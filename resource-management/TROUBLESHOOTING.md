# Troubleshooting Pod Resize Issues

## Error: "pod updates may not change fields other than..."

### Full Error Message
```
The Pod "reactor-cpu-resize-demo" is invalid: spec: Forbidden: pod updates may not change fields other than `spec.containers[*].image`,`spec.initContainers[*].image`,`spec.activeDeadlineSeconds`,`spec.tolerations` (only additions to existing tolerations),`spec.terminationGracePeriodSeconds` (allow it to be set to 1 if it was previously negative)
```

### Cause
This error occurs when the **InPlacePodVerticalScaling** feature gate is **NOT enabled** on your Kubernetes cluster.

### Quick Diagnosis

Run the feature gate check script:

```bash
chmod +x check-feature-gate.sh
./check-feature-gate.sh
```

This will tell you if in-place resizing is supported on your cluster.

## Solutions

### Option 1: Enable the Feature Gate (Requires Cluster Admin)

The InPlacePodVerticalScaling feature gate must be enabled on:
1. kube-apiserver
2. kube-controller-manager
3. kubelet

#### For Kubernetes 1.27-1.28 (Alpha)

Add this flag to all three components:
```
--feature-gates=InPlacePodVerticalScaling=true
```

#### For Kubernetes 1.29+ (Beta)

The feature may already be enabled by default. If not, add the same flag.

#### Enabling on Different Cluster Types

**Minikube:**
```bash
minikube start --feature-gates=InPlacePodVerticalScaling=true
```

**kind (Kubernetes in Docker):**

Create a config file `kind-config.yaml`:
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
featureGates:
  InPlacePodVerticalScaling: true
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        feature-gates: "InPlacePodVerticalScaling=true"
    controllerManager:
      extraArgs:
        feature-gates: "InPlacePodVerticalScaling=true"
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        feature-gates: "InPlacePodVerticalScaling=true"
```

Then create the cluster:
```bash
kind create cluster --config kind-config.yaml
```

**k3s:**
```bash
curl -sfL https://get.k3s.io | sh -s - --kube-apiserver-arg='feature-gates=InPlacePodVerticalScaling=true' \
  --kube-controller-manager-arg='feature-gates=InPlacePodVerticalScaling=true' \
  --kubelet-arg='feature-gates=InPlacePodVerticalScaling=true'
```

**GKE (Google Kubernetes Engine):**
```bash
gcloud container clusters create my-cluster \
  --enable-kubernetes-alpha \
  --cluster-version=latest \
  --region=us-central1
```

Note: Alpha features require alpha clusters in GKE.

**EKS (Amazon Elastic Kubernetes Service):**

EKS doesn't support enabling arbitrary feature gates. You'll need to use managed node groups with the feature available in the Kubernetes version, or use self-managed nodes.

**AKS (Azure Kubernetes Service):**

Similar to EKS, feature gates are managed by Azure. Check if your AKS version supports the feature.

### Option 2: Use VPA (Vertical Pod Autoscaler)

If you can't enable the feature gate, use VPA which handles resizing automatically:

```bash
# Install VPA
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler
./hack/vpa-up.sh
```

Create a VPA resource:
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: reactor-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: reactor-deployment
  updatePolicy:
    updateMode: "Auto"
```

### Option 3: Use HPA (Horizontal Pod Autoscaler)

Scale horizontally instead of vertically:

```bash
kubectl autoscale deployment reactor-deployment --cpu-percent=50 --min=1 --max=10
```

### Option 4: Manual Pod Recreation

If you can tolerate downtime, delete and recreate the pod with new resources:

```bash
# Delete the old pod
kubectl delete pod reactor-cpu-resize-demo

# Edit the YAML file with new resource values
# Then apply it
kubectl apply -f pod-cpu-resize-demo.yaml
```

### Option 5: Use a Deployment with Rolling Update

Convert your Pod to a Deployment for zero-downtime updates:

**deployment-cpu-resize-demo.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reactor-cpu-resize-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: reactor
  template:
    metadata:
      labels:
        app: reactor
        demo: cpu-resize
    spec:
      containers:
      - name: reactor
        image: nginx:latest
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "100m"
            memory: "128Mi"
      - name: cpu-monitor
        image: busybox:latest
        command:
        - /bin/sh
        - -c
        - |
          echo "Starting CPU quota monitor..."
          while true; do
            if [ -f /sys/fs/cgroup/cpu.max ]; then
              echo "[$(date '+%Y-%m-%d %H:%M:%S')] CPU quota: $(cat /sys/fs/cgroup/cpu.max)"
            else
              echo "[$(date '+%Y-%m-%d %H:%M:%S')] cpu.max not found"
            fi
            sleep 2
          done
        resources:
          requests:
            cpu: "10m"
            memory: "32Mi"
          limits:
            cpu: "50m"
            memory: "64Mi"
```

To update resources:
```bash
# Edit the deployment YAML with new values
kubectl apply -f deployment-cpu-resize-demo.yaml
# Kubernetes will perform a rolling update
```

## Verification Steps

After enabling the feature gate or using an alternative:

1. **Check feature gate is enabled:**
   ```bash
   ./check-feature-gate.sh
   ```

2. **Deploy the pod:**
   ```bash
   kubectl apply -f pod-cpu-resize-demo.yaml
   ```

3. **Try resizing:**
   ```bash
   kubectl patch pod reactor-cpu-resize-demo --patch '
   spec:
     containers:
     - name: reactor
       resources:
         limits:
           cpu: "200m"
         requests:
           cpu: "200m"
   '
   ```

4. **Check if it worked:**
   ```bash
   kubectl get pod reactor-cpu-resize-demo -o jsonpath='{.spec.containers[0].resources}'
   ```

## Common Questions

### Q: Can I use `kubectl apply` to resize?
**A:** No. Even with the feature gate enabled, you must use `kubectl patch` to modify resource requests/limits on an existing pod.

### Q: What Kubernetes version do I need?
**A:** Kubernetes 1.27+ for alpha support, 1.29+ for beta. Check your version with `kubectl version`.

### Q: Will the pod restart during resize?
**A:** Not if `resizePolicy.restartPolicy` is set to `NotRequired` for the resource. This is the whole point of in-place resizing!

### Q: Can I resize memory the same way?
**A:** Yes, but memory resize may require a container restart depending on your container runtime.

### Q: My cloud provider doesn't support feature gates. What can I do?
**A:** Use VPA, HPA, or Deployment-based rolling updates instead.

## References

- [KEP-1287: In-place Update of Pod Resources](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/1287-in-place-update-pod-resources)
- [Kubernetes Feature Gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)
- [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
