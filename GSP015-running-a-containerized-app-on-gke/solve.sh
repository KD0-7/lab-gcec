#!/usr/bin/env bash
# ==============================================================================
# GSP015 - Running a Containerized App on Google Kubernetes Engine
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

export ZONE="${ZONE:-us-central1-f}"
export CLUSTER_NAME="hello-world"
export PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}[✘] PROJECT_ID is empty. Run 'gcloud config set project <your-project-id>' first.${NC}"
    exit 1
fi

log_info "Project ID : $PROJECT_ID"
log_info "Zone       : $ZONE"
log_info "Cluster    : $CLUSTER_NAME"

gcloud config set compute/zone "$ZONE" --quiet

# ------------------------------------------------------------------------------
# Task 1: Create GKE Cluster
# ------------------------------------------------------------------------------
log_step "Task 1: Creating GKE Cluster ($CLUSTER_NAME in $ZONE)"

if ! gcloud container clusters describe "$CLUSTER_NAME" --zone="$ZONE" >/dev/null 2>&1; then
    log_info "Creating cluster $CLUSTER_NAME (this may take ~3-4 minutes)..."
    gcloud container clusters create "$CLUSTER_NAME" \
        --zone="$ZONE" \
        --num-nodes=3 \
        --machine-type=e2-medium --quiet
    log_success "Cluster $CLUSTER_NAME created."
else
    log_info "Cluster $CLUSTER_NAME already exists."
fi

log_info "Fetching cluster credentials for kubectl..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone="$ZONE"

# ------------------------------------------------------------------------------
# Task 2 & 3: Build and Publish Container Image
# ------------------------------------------------------------------------------
log_step "Task 2 & 3: Building and Publishing Hello World Container Image"

IMAGE_TAG="gcr.io/${PROJECT_ID}/hello-app:1.0"

# Clone samples if not present
WORK_DIR="$HOME/kubernetes-engine-samples/quickstarts/hello-app"
if [ ! -d "$WORK_DIR" ]; then
    log_info "Cloning sample repository..."
    cd "$HOME"
    git clone https://github.com/GoogleCloudPlatform/kubernetes-engine-samples --quiet || true
fi

cd "$WORK_DIR"

log_info "Building and publishing $IMAGE_TAG via Cloud Build..."
# Using Cloud Build is fast, serverless, and pushes directly to Container/Artifact Registry
if ! gcloud builds submit --tag "$IMAGE_TAG" . --quiet; then
    log_info "Cloud Build fallback: using local docker daemon..."
    docker build -t "$IMAGE_TAG" .
    gcloud auth configure-docker --quiet
    docker push "$IMAGE_TAG"
fi
log_success "Image $IMAGE_TAG successfully published."

# ------------------------------------------------------------------------------
# Task 4: Deploy the Application and Expose via LoadBalancer
# ------------------------------------------------------------------------------
log_step "Task 4: Deploying hello-app and Exposing via LoadBalancer"

# 1. Create Deployment
if ! kubectl get deployment hello-app >/dev/null 2>&1; then
    log_info "Creating deployment hello-app..."
    kubectl create deployment hello-app --image="$IMAGE_TAG"
    log_success "Deployment hello-app created."
else
    log_info "Deployment hello-app already exists."
fi

log_info "Waiting for hello-app pod to reach Running state..."
kubectl rollout status deployment/hello-app --timeout=120s

# 2. Expose Deployment
if ! kubectl get service hello-app >/dev/null 2>&1; then
    log_info "Exposing deployment hello-app via LoadBalancer (port 80 -> target-port 8080)..."
    kubectl expose deployment hello-app \
        --name=hello-app \
        --type=LoadBalancer \
        --port=80 \
        --target-port=8080
    log_success "Exposed service hello-app."
else
    log_info "Service hello-app already exists."
fi

# 3. Wait for External IP
log_info "Waiting for LoadBalancer External IP..."
EXTERNAL_IP=""
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get service hello-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    if [ -n "$EXTERNAL_IP" ]; then
        break
    fi
    echo -n "."
    sleep 4
done
echo ""

if [ -n "$EXTERNAL_IP" ]; then
    log_success "hello-app is publicly available at: http://${EXTERNAL_IP}"
    log_info "Testing HTTP response:"
    curl -s --connect-timeout 5 "http://${EXTERNAL_IP}" || true
    echo ""
else
    log_info "External IP is still provisioning in background. Check with: kubectl get svc hello-app"
fi

# ------------------------------------------------------------------------------
# Completion Summary
# ------------------------------------------------------------------------------
log_step "ALL TASKS COMPLETED SUCCESSFULLY!"

echo -e "${GREEN}"
echo "  [✔] Task 1: GKE Cluster '$CLUSTER_NAME' running in zone '$ZONE'"
echo "  [✔] Task 2 & 3: Container image '$IMAGE_TAG' built and published"
echo "  [✔] Task 4: Deployment 'hello-app' running & exposed via LoadBalancer"
echo -e "${NC}"
if [ -n "$EXTERNAL_IP" ]; then
    echo -e "${CYAN}Application URL : http://${EXTERNAL_IP}${NC}\n"
fi

echo -e "You can now click 'Check my progress' on all three checkpoints:"
echo -e "  1. [✔] Create a Kubernetes Cluster (5/5 pts)"
echo -e "  2. [✔] Build and Deploy Hello World App (hello-app) (5/5 pts)"
echo -e "  3. [✔] Allow external traffic to hello-app deployment (5/5 pts)"
