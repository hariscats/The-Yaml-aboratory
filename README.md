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
- `pod-cpu-resize-demo.yaml` - In-place CPU resize with resizePolicy

### 🌐 Networking
**Location**: `networking/`

Network policies, services, ingress, and connectivity:
- Network policies for pod-to-pod communication
- Service types (ClusterIP, NodePort, LoadBalancer)
- Ingress controllers and routing
- DNS and service discovery
- CNI plugins and configurations

### 💾 Storage
**Location**: `storage/`

Persistent volumes, storage classes, and data management:
- PersistentVolume and PersistentVolumeClaim patterns
- Storage classes and dynamic provisioning
- StatefulSets with persistent storage
- Volume snapshots and cloning
- CSI driver demonstrations

### 🔒 Security
**Location**: `security/`

Security contexts, policies, and hardening techniques:
- Pod Security Standards (PSS)
- SecurityContext configurations
- RBAC policies
- Network policies for security
- Secrets and ConfigMap management
- Service accounts and identity

### 📅 Scheduling
**Location**: `scheduling/`

Pod placement, affinity, and scheduling controls:
- Node affinity and anti-affinity
- Pod affinity and anti-affinity
- Taints and tolerations
- Priority classes
- Topology spread constraints

### 📈 Observability
**Location**: `observability/`

Monitoring, logging, and debugging:
- Liveness, readiness, and startup probes
- Prometheus metrics and monitoring
- Logging patterns and sidecar logging
- Debug containers
- Events and troubleshooting

### ⚡ Autoscaling
**Location**: `autoscaling/`

Horizontal and vertical pod autoscaling:
- Horizontal Pod Autoscaler (HPA)
- Vertical Pod Autoscaler (VPA)
- Cluster Autoscaler integration
- Custom metrics and scaling policies
- KEDA (Kubernetes Event-Driven Autoscaling)

### 🚀 Workloads
**Location**: `workloads/`

Different workload types and patterns:
- Deployments and ReplicaSets
- StatefulSets for stateful applications
- DaemonSets for node-level services
- Jobs and CronJobs
- Init containers and lifecycle hooks

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
| Resource Management | [CPU Resize](resource-management/) | 1.27+ | In-place pod CPU resize without restart |

*More demos coming soon!*

## Roadmap

Upcoming demos:
- Memory resize demonstrations
- Network policy examples
- StatefulSet with persistent storage
- HPA with custom metrics
- Pod Security Standards enforcement
- Multi-container pod patterns

## License

See [LICENSE](LICENSE) file for details.

## Feedback

Found an issue or have a suggestion? Please open an issue or submit a pull request!

---

**Happy YAML-ing! 🎯**
