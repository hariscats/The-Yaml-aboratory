# The YAML-aboratory 🔬

A comprehensive collection of Kubernetes YAML demonstrations showcasing various container use-cases, features, and best practices.

## Repository Structure

This repository is organized into sections based on different Kubernetes capabilities and use-cases:

### 📊 Resource Management
**Location**: `resource-management/`

Demonstrations of CPU, memory, and resource allocation features:
- **In-place Pod Resize**: CPU/memory resizing without pod restarts (K8s 1.27+)
- Resource quotas and limit ranges
- QoS classes (Guaranteed, Burstable, BestEffort)
- Resource management best practices

**Current Demos**:
- `pod-cpu-resize-demo.yaml` - In-place CPU resize with resizePolicy and monitoring
- `pod-memory-resize-demo.yaml` - In-place memory resize with cgroup monitoring

### 🌐 Networking
**Location**: `networking/`

Network policies, services, ingress, and connectivity:
- Network policies for pod-to-pod communication
- Service types (ClusterIP, NodePort, LoadBalancer)
- Ingress controllers and routing
- DNS and service discovery
- CNI plugins and configurations

**Current Demos**:
- `network-policy-demo.yaml` - Network policies for pod-to-pod communication control
- `ingress-routing-demo.yaml` - Host and path-based HTTP routing with Ingress

### 💾 Storage
**Location**: `storage/`

Persistent volumes, storage classes, and data management:
- PersistentVolume and PersistentVolumeClaim patterns
- Storage classes and dynamic provisioning
- StatefulSets with persistent storage
- Volume snapshots and cloning
- CSI driver demonstrations

**Current Demos**:
- `persistent-storage-demo.yaml` - PV, PVC, StorageClass, and StatefulSet storage patterns

### 🔒 Security
**Location**: `security/`

Security contexts, policies, and hardening techniques:
- Pod Security Standards (PSS)
- SecurityContext configurations
- RBAC policies
- Network policies for security
- Secrets and ConfigMap management
- Service accounts and identity

**Current Demos**:
- `security-context-demo.yaml` - Pod Security Standards and SecurityContext best practices
- `rbac-demo.yaml` - Least-privilege Role, RoleBinding, ClusterRole, and ClusterRoleBinding patterns

### 📅 Scheduling
**Location**: `scheduling/`

Pod placement, affinity, and scheduling controls:
- Node affinity and anti-affinity
- Pod affinity and anti-affinity
- Taints and tolerations
- Priority classes
- Topology spread constraints

**Current Demos**:
- `affinity-demo.yaml` - Pod/node affinity, anti-affinity, and topology spread constraints

### 📈 Observability
**Location**: `observability/`

Monitoring, logging, and debugging:
- Liveness, readiness, and startup probes
- Prometheus metrics and monitoring
- Logging patterns and sidecar logging
- Debug containers
- Events and troubleshooting

**Current Demos**:
- `health-probes-demo.yaml` - Liveness, readiness, and startup probes configuration

### ⚡ Autoscaling
**Location**: `autoscaling/`

Horizontal and vertical pod autoscaling:
- Horizontal Pod Autoscaler (HPA)
- Vertical Pod Autoscaler (VPA)
- Cluster Autoscaler integration
- Custom metrics and scaling policies
- KEDA (Kubernetes Event-Driven Autoscaling)

**Current Demos**:
- `hpa-demo.yaml` - Horizontal Pod Autoscaler with CPU/memory metrics and scaling policies
- `vpa-demo.yaml` - Vertical Pod Autoscaler recommendations and update policies

### 🚀 Workloads
**Location**: `workloads/`

Different workload types and patterns:
- Deployments and ReplicaSets
- StatefulSets for stateful applications
- DaemonSets for node-level services
- Jobs and CronJobs
- Init containers and lifecycle hooks

**Current Demos**:
- `workload-types-demo.yaml` - Deployment, StatefulSet, DaemonSet, Job, CronJob, and multi-container patterns

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/hariscats/The-Yaml-aboratory.git
   cd The-Yaml-aboratory
   ```

2. **Browse demos by category**:
   ```bash
   ls -la resource-management/
   ls -la networking/
   # etc.
   ```

3. **Apply a demo**:
   ```bash
   kubectl apply -f resource-management/pod-cpu-resize-demo.yaml
   ```

4. **Read the documentation**:
   Each demo folder contains its own README with specific instructions.

## Prerequisites

- Kubernetes cluster (version varies by demo)
- `kubectl` CLI configured
- Basic understanding of Kubernetes concepts

Some demos may require:
- Specific Kubernetes versions
- Feature gates enabled
- Additional controllers or operators

## Contributing

Each demo should include:
- ✅ Well-commented YAML manifests
- ✅ README with prerequisites and instructions
- ✅ Real-world use-case explanation
- ✅ Testing and verification steps
- ✅ Cleanup instructions

## Demo Index

| Category | Demo | Kubernetes Version | Description |
|----------|------|-------------------|-------------|
| Resource Management | [CPU Resize](resource-management/pod-cpu-resize-demo.yaml) | 1.27+ | In-place pod CPU resize without restart |
| Resource Management | [Memory Resize](resource-management/pod-memory-resize-demo.yaml) | 1.27+ | In-place pod memory resize with cgroup monitoring |
| Observability | [Health Probes](observability/health-probes-demo.yaml) | 1.16+ | Liveness, readiness, and startup probes |
| Autoscaling | [HPA](autoscaling/hpa-demo.yaml) | 1.23+ | Horizontal Pod Autoscaler with CPU/memory metrics |
| Autoscaling | [VPA](autoscaling/vpa-demo.yaml) | 1.23+ | Vertical Pod Autoscaler recommendations and automated right-sizing |
| Networking | [Network Policies](networking/network-policy-demo.yaml) | 1.7+ | Pod-to-pod communication control with network policies |
| Networking | [Ingress Routing](networking/ingress-routing-demo.yaml) | 1.19+ | Host and path-based HTTP routing with Ingress |
| Scheduling | [Affinity Rules](scheduling/affinity-demo.yaml) | 1.18+ | Pod/node affinity, anti-affinity, and topology spread |
| Security | [Security Context](security/security-context-demo.yaml) | 1.25+ | Pod Security Standards and SecurityContext hardening |
| Security | [RBAC Policies](security/rbac-demo.yaml) | 1.8+ | Least-privilege API access with RBAC policies |
| Storage | [Persistent Storage](storage/persistent-storage-demo.yaml) | 1.21+ | PV, PVC, StorageClass, and StatefulSet storage |
| Workloads | [Workload Types](workloads/workload-types-demo.yaml) | 1.21+ | Deployment, StatefulSet, DaemonSet, Job, CronJob patterns |

## Roadmap

Upcoming demos:
- KEDA event-driven autoscaling
- Service mesh integration
- Volume snapshots and cloning
- Custom metrics for HPA

## License

See [LICENSE](LICENSE) file for details.

## Feedback

Found an issue or have a suggestion? Please open an issue or submit a pull request!

---

**Happy YAML-ing! 🎯**
