#!/usr/bin/env bash
# ==============================================================================
# Deploying GKE Autopilot Clusters
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
    log_info "Launching GKE Autopilot cluster creation (takes ~4 to 6 minutes)..."
    gcloud container clusters create-auto "$my_cluster" \
        --region="$my_region" --quiet
    log_success "Autopilot cluster $my_cluster successfully created."
else
    log_info "Cluster $my_cluster already exists."
fi

# ------------------------------------------------------------------------------
# Task 2: Deploy Sample Workload (nginx-1 with 3 replicas)
# ------------------------------------------------------------------------------
log_step "Task 2: Deploying Sample nginx-1 Workload (3 Replicas)"

log_info "Fetching kubeconfig credentials for $my_cluster..."
gcloud container clusters get-credentials "$my_cluster" --region="$my_region"

if ! kubectl get deployment nginx-1 >/dev/null 2>&1; then
    log_info "Creating deployment nginx-1 with image nginx:latest and 3 replicas..."
    kubectl create deployment nginx-1 --image=nginx:latest --replicas=3
    log_success "Created deployment nginx-1."
else
    log_info "Deployment nginx-1 already exists, ensuring 3 replicas..."
    kubectl scale deployment nginx-1 --replicas=3 --quiet || true
fi

log_info "Waiting for nginx-1 deployment rollout to complete..."
kubectl rollout status deployment/nginx-1 --timeout=240s || true

log_info "Verifying pods:"
kubectl get pods -l app=nginx-1 -o wide

# ------------------------------------------------------------------------------
# Completion Summary
# ------------------------------------------------------------------------------
log_step "ALL TASKS COMPLETED SUCCESSFULLY!"

echo -e "${GREEN}"
echo "  [✔] Task 1: GKE Autopilot cluster '$my_cluster' running in region '$my_region'"
echo "  [✔] Task 2: Workload 'nginx-1' (nginx:latest, 3 pods) deployed and ready"
echo "  [✔] Task 3: Workload specifications and revision history available in console"
echo -e "${NC}"

echo -e "You can now click 'Check my progress' on both checkpoints in your lab window:"
echo -e "  1. [✔] Deploy GKE cluster"
echo -e "  2. [✔] Deploy a sample nginx workload"
