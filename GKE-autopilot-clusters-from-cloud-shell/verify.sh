#!/usr/bin/env bash
# ==============================================================================
# Deploying GKE Autopilot Clusters from Cloud Shell - Verification Script
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
echo -e "${CYAN}Verifying GKE Autopilot Cluster & Workloads${NC}"
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

# Check Pods
echo -e "\n${YELLOW}--- 2. Checking Deployed Pods ---${NC}"
kubectl get pods -o wide

# Check Services
echo -e "\n${YELLOW}--- 3. Checking Services & Endpoints ---${NC}"
kubectl get svc -o wide

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${GREEN}[✔] Verification complete.${NC}"
echo -e "${GREEN}====================================================================${NC}"
