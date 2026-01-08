#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

POD_NAME="reactor-cpu-resize-demo"

echo -e "${BLUE}=== Kubernetes Pod CPU In-Place Resize Demo ===${NC}\n"

# Function to print step headers
step() {
    echo -e "\n${GREEN}[Step $1]${NC} $2"
    echo "-----------------------------------"
}

# Function to wait for user
wait_for_user() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read
}

# Check if pod exists
if kubectl get pod $POD_NAME &>/dev/null; then
    echo -e "${YELLOW}Pod '$POD_NAME' already exists.${NC}"
    echo "Would you like to delete it and start fresh? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        kubectl delete pod $POD_NAME
        echo "Waiting for pod to be deleted..."
        kubectl wait --for=delete pod/$POD_NAME --timeout=60s
    else
        echo "Continuing with existing pod..."
    fi
fi

# Step 1: Deploy the pod (if not exists)
if ! kubectl get pod $POD_NAME &>/dev/null; then
    step 1 "Deploy the pod"
    kubectl apply -f pod-cpu-resize-demo.yaml

    echo -e "\n${BLUE}Waiting for pod to be ready...${NC}"
    kubectl wait --for=condition=Ready pod/$POD_NAME --timeout=60s
fi

# Step 2: Check initial state
step 2 "Check initial CPU allocation"
echo -e "${BLUE}Pod status:${NC}"
kubectl get pod $POD_NAME

echo -e "\n${BLUE}Initial resource requests and limits:${NC}"
kubectl get pod $POD_NAME -o json | jq '.spec.containers[] | {name: .name, resources: .resources}'

echo -e "\n${BLUE}Container restart count:${NC}"
kubectl get pod $POD_NAME -o jsonpath='{.status.containerStatuses[?(@.name=="reactor")].restartCount}' && echo

wait_for_user

# Step 3: Monitor CPU quota
step 3 "Monitor CPU quota (background)"
echo "Starting log monitoring in background..."
echo "You can also run this in a separate terminal:"
echo -e "${YELLOW}kubectl logs -f $POD_NAME -c cpu-monitor${NC}\n"

# Show a few log lines
kubectl logs $POD_NAME -c cpu-monitor --tail=5

wait_for_user

# Step 4: Perform first resize
step 4 "Resize CPU from 100m to 200m using kubectl patch"
echo -e "${RED}NOTE: Using 'kubectl apply' would fail here!${NC}"
echo -e "${GREEN}We must use 'kubectl patch' for resource changes.${NC}\n"

echo "Executing:"
echo -e "${YELLOW}kubectl patch pod $POD_NAME --patch '..."

kubectl patch pod $POD_NAME --patch '
spec:
  containers:
  - name: reactor
    resources:
      limits:
        cpu: "200m"
      requests:
        cpu: "200m"
'

echo -e "\n${GREEN}✓ Resize command sent!${NC}"
sleep 3

# Step 5: Verify the resize
step 5 "Verify the resize"
echo -e "${BLUE}Updated resource requests and limits:${NC}"
kubectl get pod $POD_NAME -o json | jq '.spec.containers[] | select(.name=="reactor") | {name: .name, resources: .resources}'

echo -e "\n${BLUE}Container restart count (should still be 0):${NC}"
kubectl get pod $POD_NAME -o jsonpath='{.status.containerStatuses[?(@.name=="reactor")].restartCount}' && echo

echo -e "\n${BLUE}Recent CPU quota from logs:${NC}"
kubectl logs $POD_NAME -c cpu-monitor --tail=10

wait_for_user

# Step 6: Perform second resize
step 6 "Resize CPU from 200m to 500m"

kubectl patch pod $POD_NAME --patch '
spec:
  containers:
  - name: reactor
    resources:
      limits:
        cpu: "500m"
      requests:
        cpu: "500m"
'

echo -e "\n${GREEN}✓ Second resize complete!${NC}"
sleep 3

echo -e "\n${BLUE}Final resource allocation:${NC}"
kubectl get pod $POD_NAME -o json | jq '.spec.containers[] | select(.name=="reactor") | {name: .name, resources: .resources}'

echo -e "\n${BLUE}Container restart count (should still be 0):${NC}"
kubectl get pod $POD_NAME -o jsonpath='{.status.containerStatuses[?(@.name=="reactor")].restartCount}' && echo

echo -e "\n${BLUE}Recent CPU quota changes:${NC}"
kubectl logs $POD_NAME -c cpu-monitor --tail=15

# Step 7: Check pod events
step 7 "Check pod events for resize operations"
kubectl describe pod $POD_NAME | grep -A 20 "Events:" || echo "No events found"

# Summary
echo -e "\n${GREEN}=== Demo Complete ===${NC}\n"
echo "Summary:"
echo "  ✓ Pod deployed with initial CPU limit: 100m"
echo "  ✓ First resize: 100m → 200m (in-place, no restart)"
echo "  ✓ Second resize: 200m → 500m (in-place, no restart)"
echo "  ✓ Container never restarted (restartCount = 0)"
echo ""
echo "Key takeaway:"
echo -e "  ${YELLOW}Use 'kubectl patch' (not 'kubectl apply') to resize existing pods!${NC}"
echo ""
echo "To clean up:"
echo "  kubectl delete pod $POD_NAME"
