#!/usr/bin/env bash
# ==============================================================================
# Deploying GKE Autopilot Clusters - Verification Script
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

my_region="${my_region:-us-west1}"
my_cluster="${my_cluster:-autopilot-cluster-1}"

echo -e "${BLUE}====================================================================${NC}"
echo -e "${CYAN}Verifying GKE Autopilot Cluster & nginx-1 Workload${NC}"
echo -e "${BLUE}====================================================================${NC}"

# Check Cluster
echo -e "\n${YELLOW}--- 1. Checking Cluster Status ---${NC}"
if gcloud container clusters describe "$my_cluster" --region="$my_region" >/dev/null 2>&1; then
    STATUS=$(gcloud container clusters describe "$my_cluster" --region="$my_region" --format='value(status)')
    MODE=$(gcloud container clusters describe "$my_cluster" --region="$my_region" --format='value(autopilot.enabled)')
    echo -e "${GREEN}[✔] Cluster '$my_cluster' found. Status: ${STATUS}, Autopilot: ${MODE}${NC}"
else
    echo -e "${RED}[✘] Cluster '$my_cluster' not found in $my_region!${NC}"
fi

# Check Workload
echo -e "\n${YELLOW}--- 2. Checking nginx-1 Deployment ---${NC}"
if kubectl get deployment nginx-1 >/dev/null 2>&1; then
    REPLICAS=$(kubectl get deployment nginx-1 -o jsonpath='{.status.readyReplicas}')
    DESIRED=$(kubectl get deployment nginx-1 -o jsonpath='{.spec.replicas}')
    echo -e "${GREEN}[✔] Deployment nginx-1 exists: ${REPLICAS}/${DESIRED} replicas ready.${NC}"
    kubectl get pods -l app=nginx-1 -o wide
else
    echo -e "${RED}[✘] Deployment nginx-1 not found!${NC}"
fi

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${GREEN}[✔] Verification complete.${NC}"
echo -e "${GREEN}====================================================================${NC}"
