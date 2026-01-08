#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Checking InPlacePodVerticalScaling Feature Gate ===${NC}\n"

# Check Kubernetes version
echo -e "${BLUE}1. Checking Kubernetes version:${NC}"
K8S_VERSION=$(kubectl version --short 2>/dev/null | grep "Server Version" | awk '{print $3}')
if [ -z "$K8S_VERSION" ]; then
    K8S_VERSION=$(kubectl version -o json 2>/dev/null | jq -r '.serverVersion.gitVersion')
fi

echo "   Kubernetes version: $K8S_VERSION"

# Extract major.minor version
VERSION_NUM=$(echo $K8S_VERSION | sed 's/v//' | cut -d'.' -f1-2)

echo -e "\n${BLUE}2. Feature gate requirements:${NC}"
echo "   - Kubernetes 1.27+: InPlacePodVerticalScaling (alpha, must enable)"
echo "   - Kubernetes 1.29+: InPlacePodVerticalScaling (beta, may be enabled by default)"

# Check if we can access node information
echo -e "\n${BLUE}3. Checking kubelet feature gates:${NC}"

# Try to check kubelet config
KUBELET_CONFIG=$(kubectl get --raw /api/v1/nodes 2>/dev/null | jq -r '.items[0].metadata.name' | xargs -I {} kubectl get --raw /api/v1/nodes/{}/proxy/configz 2>/dev/null || echo "")

if [ -n "$KUBELET_CONFIG" ]; then
    if echo "$KUBELET_CONFIG" | grep -q "InPlacePodVerticalScaling"; then
        echo -e "   ${GREEN}✓ InPlacePodVerticalScaling found in kubelet config${NC}"
        echo "$KUBELET_CONFIG" | grep "InPlacePodVerticalScaling"
    else
        echo -e "   ${RED}✗ InPlacePodVerticalScaling NOT found in kubelet config${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠ Unable to access kubelet config (requires cluster-admin)${NC}"
fi

# Try to create a test pod with resize policy
echo -e "\n${BLUE}4. Testing if resize is supported (creating test pod):${NC}"

TEST_POD_NAME="resize-feature-test-$$"

cat <<EOF | kubectl apply -f - 2>&1 | tee /tmp/test-output.txt
apiVersion: v1
kind: Pod
metadata:
  name: $TEST_POD_NAME
spec:
  containers:
  - name: test
    image: busybox:latest
    command: ["sleep", "30"]
    resources:
      requests:
        cpu: "100m"
      limits:
        cpu: "100m"
    resizePolicy:
    - resourceName: cpu
      restartPolicy: NotRequired
  restartPolicy: Never
EOF

if grep -q "resizePolicy" /tmp/test-output.txt && grep -q "error\|invalid\|unknown" /tmp/test-output.txt; then
    echo -e "\n   ${RED}✗ Feature gate is NOT enabled${NC}"
    echo -e "   ${RED}The cluster rejected the 'resizePolicy' field${NC}"
    FEATURE_ENABLED=false
elif kubectl get pod $TEST_POD_NAME &>/dev/null; then
    echo -e "\n   ${GREEN}✓ Feature gate appears to be enabled${NC}"
    echo -e "   ${GREEN}Test pod created with resizePolicy${NC}"

    # Wait for pod to be ready
    kubectl wait --for=condition=Ready pod/$TEST_POD_NAME --timeout=30s 2>/dev/null

    # Try to patch it
    echo -e "\n${BLUE}5. Testing actual resize capability:${NC}"
    if kubectl patch pod $TEST_POD_NAME --patch '
spec:
  containers:
  - name: test
    resources:
      limits:
        cpu: "200m"
      requests:
        cpu: "200m"
' 2>&1 | tee /tmp/patch-output.txt; then
        if grep -q "Forbidden\|invalid" /tmp/patch-output.txt; then
            echo -e "   ${RED}✗ Resize NOT working - feature gate not fully enabled${NC}"
            FEATURE_ENABLED=false
        else
            echo -e "   ${GREEN}✓ Resize is working!${NC}"
            FEATURE_ENABLED=true
        fi
    else
        echo -e "   ${RED}✗ Resize failed${NC}"
        cat /tmp/patch-output.txt
        FEATURE_ENABLED=false
    fi

    FEATURE_ENABLED=true
else
    echo -e "\n   ${YELLOW}⚠ Unable to determine feature gate status${NC}"
    FEATURE_ENABLED=unknown
fi

# Cleanup test pod
kubectl delete pod $TEST_POD_NAME --wait=false 2>/dev/null
rm -f /tmp/test-output.txt /tmp/patch-output.txt

# Final verdict
echo -e "\n${BLUE}=== Summary ===${NC}\n"

if [ "$FEATURE_ENABLED" = true ]; then
    echo -e "${GREEN}✓ In-place pod resizing IS supported on this cluster${NC}"
    echo ""
    echo "You can use:"
    echo "  kubectl patch pod <pod-name> --patch '...'"
elif [ "$FEATURE_ENABLED" = false ]; then
    echo -e "${RED}✗ In-place pod resizing is NOT supported on this cluster${NC}"
    echo ""
    echo "The InPlacePodVerticalScaling feature gate is not enabled."
    echo ""
    echo "To enable it, you need cluster-admin access to:"
    echo ""
    echo "1. Add to kube-apiserver flags:"
    echo "   --feature-gates=InPlacePodVerticalScaling=true"
    echo ""
    echo "2. Add to kube-controller-manager flags:"
    echo "   --feature-gates=InPlacePodVerticalScaling=true"
    echo ""
    echo "3. Add to kubelet flags:"
    echo "   --feature-gates=InPlacePodVerticalScaling=true"
    echo ""
    echo "Alternative: Use kubectl rollout restart or delete/recreate the pod"
else
    echo -e "${YELLOW}⚠ Unable to determine if in-place resizing is supported${NC}"
    echo "Please check with your cluster administrator"
fi
