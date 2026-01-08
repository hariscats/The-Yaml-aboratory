# Kubernetes Pod CPU Resize Demo

This repository demonstrates the **in-place pod resize** feature introduced in Kubernetes 1.27 (alpha) and enhanced in subsequent versions, including 1.35.

## Overview

The demo showcases how Kubernetes can resize container resources (CPU and memory) without restarting the pod when the `resizePolicy` is set to `NotRequired`.

## Files

- `pod-cpu-resize-demo.yaml` - Pod definition with resize policies configured

## Pod Configuration

### Main Container: `reactor`
- **Initial CPU limit**: 100m (0.1 CPU cores)
- **ResizePolicy**: `NotRequired` for CPU (no restart needed on resize)
- **Image**: nginx:latest

### Sidecar Container: `cpu-monitor`
- **Purpose**: Monitors and displays the current CPU quota every 2 seconds
- **Monitors**: `/sys/fs/cgroup/cpu.max` (cgroup v2) or legacy cgroup v1 paths
- **Initial CPU limit**: 50m

## Prerequisites

- Kubernetes cluster version 1.27+ (1.35 recommended)
- The `InPlacePodVerticalScaling` feature gate must be enabled
- kubectl configured to access your cluster

### Enable Feature Gate

For Kubernetes 1.27-1.28 (alpha):
```bash
# Add to kube-apiserver, kube-controller-manager, and kubelet flags:
--feature-gates=InPlacePodVerticalScaling=true
```

For Kubernetes 1.29+ (beta), this may be enabled by default.

## Usage

### 1. Deploy the Pod

```bash
kubectl apply -f pod-cpu-resize-demo.yaml
```

### 2. Verify Pod is Running

```bash
kubectl get pod reactor-cpu-resize-demo
```

### 3. Monitor CPU Quota in Real-Time

Open a terminal and watch the sidecar container logs:

```bash
kubectl logs -f reactor-cpu-resize-demo -c cpu-monitor
```

You should see output like:
```
Starting CPU quota monitor...
[2026-01-08 12:00:00] CPU quota: 100000 200000
[2026-01-08 12:00:02] CPU quota: 100000 200000
```

The format is `quota/period` in microseconds. For example, `100000/200000` means:
- Quota: 100,000 microseconds
- Period: 200,000 microseconds
- Effective CPU: 100,000/200,000 = 0.5 = 50% of one core (or 500m)

### 4. Perform In-Place CPU Resize

In another terminal, resize the reactor container's CPU limit:

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

Or increase it to 500m:

```bash
kubectl patch pod reactor-cpu-resize-demo --patch '
spec:
  containers:
  - name: reactor
    resources:
      limits:
        cpu: "500m"
      requests:
        cpu: "500m"
'
```

### 5. Observe the Changes

In the monitoring terminal, you should see the CPU quota change **without pod restart**:

```
[2026-01-08 12:00:00] CPU quota: 100000 200000
[2026-01-08 12:00:02] CPU quota: 100000 200000
[2026-01-08 12:00:04] CPU quota: 200000 200000  # <- Changed!
[2026-01-08 12:00:06] CPU quota: 200000 200000
```

### 6. Check Pod Events

```bash
kubectl describe pod reactor-cpu-resize-demo
```

Look for events indicating the resize operation completed successfully.

### 7. Verify No Restart Occurred

```bash
kubectl get pod reactor-cpu-resize-demo -o jsonpath='{.status.containerStatuses[?(@.name=="reactor")].restartCount}'
```

The restart count should remain at 0, proving the resize happened in-place!

## Understanding ResizePolicy

The `resizePolicy` field controls whether a container restart is required when resources are resized:

- **`NotRequired`**: Resources can be resized without restarting the container (in-place)
- **`RestartContainer`**: Container must be restarted for the new resources to take effect

```yaml
resizePolicy:
- resourceName: cpu
  restartPolicy: NotRequired
- resourceName: memory
  restartPolicy: NotRequired
```

## Cleanup

```bash
kubectl delete pod reactor-cpu-resize-demo
```

## Key Benefits

1. **Zero Downtime**: Resize resources without pod restarts
2. **Dynamic Scaling**: Adjust resources based on actual usage
3. **Cost Optimization**: Right-size containers without service interruption
4. **Improved SLAs**: Maintain service availability during resource adjustments

## Notes

- CPU resizes typically don't require container restart
- Memory resizes may require restart depending on the container runtime
- The actual cgroup path may vary depending on your Kubernetes version and container runtime
  - cgroup v2: `/sys/fs/cgroup/cpu.max`
  - cgroup v1: `/sys/fs/cgroup/cpu/cpu.cfs_quota_us`

## References

- [KEP-1287: In-place Update of Pod Resources](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/1287-in-place-update-pod-resources)
- [Kubernetes Documentation: Resize CPU and Memory Resources](https://kubernetes.io/docs/tasks/configure-pod-container/resize-container-resources/)
