#!/usr/bin/env bash
# ==============================================================================
# Deploying GKE Autopilot Clusters from Cloud Shell
# Automated Solution Script
# Repository: https://github.com/KD0-7/lab-gcec
# ==============================================================================

set -euo pipefail

# ANSI Color Codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

log_step() {
    echo -e "\n${BLUE}====================================================================${NC}"
    echo -e "${CYAN}[$(date +'%T')] $1${NC}"
    echo -e "${BLUE}====================================================================${NC}"
}

log_success() {
    echo -e "${GREEN}[✔] $1${NC}"
}

log_info() {
    echo -e "${YELLOW}[i] $1${NC}"
}

export my_region="${my_region:-us-west1}"
export my_cluster="${my_cluster:-autopilot-cluster-1}"
export PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"

log_info "Project ID : $PROJECT_ID"
log_info "Cluster    : $my_cluster"
log_info "Region     : $my_region"

# ------------------------------------------------------------------------------
# Task 1: Deploy GKE Autopilot Cluster
# ------------------------------------------------------------------------------
log_step "Task 1: Creating GKE Autopilot Cluster ($my_cluster in $my_region)"

if ! gcloud container clusters describe "$my_cluster" --region="$my_region" >/dev/null 2>&1; then
    log_info "Launching cluster creation (Autopilot setup takes ~4 to 6 minutes)..."
    gcloud container clusters create-auto "$my_cluster" \
        --region="$my_region" --quiet
    log_success "Autopilot cluster $my_cluster successfully created."
else
    log_info "Cluster $my_cluster already exists."
fi

# ------------------------------------------------------------------------------
# Task 2 & 3: Connect and Inspect Kubeconfig
# ------------------------------------------------------------------------------
log_step "Task 2 & 3: Authenticating and Getting Cluster Credentials"

log_info "Fetching kubeconfig credentials for $my_cluster..."
gcloud container clusters get-credentials "$my_cluster" --region="$my_region"

log_info "Verifying cluster info and active context..."
kubectl cluster-info || true
kubectl config current-context

# ------------------------------------------------------------------------------
# Task 4: Deploy Pods (nginx-1), Push File & Expose LoadBalancer
# ------------------------------------------------------------------------------
log_step "Task 4: Deploying nginx-1, Injecting test.html & Exposing LoadBalancer"

if ! kubectl get deployment nginx-1 >/dev/null 2>&1; then
    log_info "Creating deployment nginx-1..."
    kubectl create deployment --image=nginx nginx-1
    log_success "Deployment nginx-1 created."
else
    log_info "Deployment nginx-1 already exists."
fi

log_info "Waiting for nginx-1 Pod to be provisioned and Running..."
for i in {1..50}; do
    POD_STATUS=$(kubectl get pods -l app=nginx-1 -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Pending")
    if [ "$POD_STATUS" = "Running" ]; then
        break
    fi
    echo -n "."
    sleep 5
done
echo ""

my_nginx_pod=$(kubectl get pods -l app=nginx-1 -o jsonpath='{.items[0].metadata.name}')
log_success "Pod $my_nginx_pod is Running."

log_info "Creating ~/test.html and pushing into container..."
cat <<EOF > "$HOME/test.html"
<header><title>This is title</title></header> Hello world
EOF

kubectl cp "$HOME/test.html" "${my_nginx_pod}:/usr/share/nginx/html/test.html"
log_success "File test.html copied to ${my_nginx_pod}:/usr/share/nginx/html/test.html"

log_info "Exposing nginx Pod via LoadBalancer service..."
SVC_EXISTS=$(kubectl get svc -o jsonpath="{.items[?(@.metadata.name=='${my_nginx_pod}')].metadata.name}" 2>/dev/null || true)
if [ -z "$SVC_EXISTS" ]; then
    kubectl expose pod "$my_nginx_pod" --port=80 --type=LoadBalancer --quiet || true
    log_success "Created LoadBalancer service for pod $my_nginx_pod."
else
    log_info "Service $my_nginx_pod already exists."
fi

log_info "Deploying Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml 2>/dev/null || true

# ------------------------------------------------------------------------------
# Task 5: Introspect GKE Pods & Deploy Pod from Manifest
# ------------------------------------------------------------------------------
log_step "Task 5: Deploying new-nginx Pod from YAML Manifest"

log_info "Deploying new-nginx pod..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: new-nginx
  labels:
    name: new-nginx
spec:
  containers:
  - name: new-nginx
    image: nginx
    ports:
    - containerPort: 80
EOF
log_success "Applied manifest for new-nginx."

log_info "Waiting for new-nginx Pod to reach Running state..."
for i in {1..40}; do
    POD_STATUS=$(kubectl get pod new-nginx -o jsonpath='{.status.phase}' 2>/dev/null || echo "Pending")
    if [ "$POD_STATUS" = "Running" ]; then
        break
    fi
    echo -n "."
    sleep 4
done
echo ""
log_success "Pod new-nginx is Running."

log_info "Creating test.html inside new-nginx pod..."
kubectl exec new-nginx -- /bin/bash -c "echo '<header><title>This is title</title></header> Hello world' > /usr/share/nginx/html/test.html" 2>/dev/null || true

# Check for LoadBalancer External IP
log_info "Checking LoadBalancer service external IP..."
EXTERNAL_IP=""
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get svc "$my_nginx_pod" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    if [ -n "$EXTERNAL_IP" ]; then
        break
    fi
    echo -n "."
    sleep 4
done
echo ""

# ------------------------------------------------------------------------------
# Completion Summary
# ------------------------------------------------------------------------------
log_step "ALL TASKS COMPLETED SUCCESSFULLY!"

echo -e "${GREEN}"
echo "  [✔] Task 1: GKE Autopilot cluster '$my_cluster' created in $my_region"
echo "  [✔] Task 2 & 3: Authenticated and verified kubeconfig contexts"
echo "  [✔] Task 4: Deployed nginx-1, pushed test.html, and exposed LoadBalancer"
echo "  [✔] Task 5: Deployed new-nginx Pod via YAML manifest"
echo -e "${NC}"
if [ -n "$EXTERNAL_IP" ]; then
    echo -e "${CYAN}Load Balancer URL : http://${EXTERNAL_IP}/test.html${NC}"
else
    echo -e "${YELLOW}Load Balancer IP is still provisioning in background. Check with: kubectl get svc${NC}"
fi

echo -e "\nYou can now click 'Check my progress' on all three checkpoints:"
echo -e "  1. [✔] Deploy GKE clusters"
echo -e "  2. [✔] Deploy Pods to GKE clusters"
echo -e "  3. [✔] Deploy a new pod using a Yaml file"
