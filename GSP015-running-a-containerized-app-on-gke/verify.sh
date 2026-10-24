#!/usr/bin/env bash
# ==============================================================================
# GSP015 - Verification Script
# Validates GKE Cluster, Deployment, and Service Status
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

ZONE="${ZONE:-us-central1-f}"
CLUSTER_NAME="hello-world"

echo -e "${BLUE}====================================================================${NC}"
echo -e "${CYAN}GSP015: Verifying GKE Cluster & hello-app Workload${NC}"
echo -e "${BLUE}====================================================================${NC}"

# Check Cluster
echo -e "\n${YELLOW}--- 1. Checking GKE Cluster ---${NC}"
if gcloud container clusters describe "$CLUSTER_NAME" --zone="$ZONE" >/dev/null 2>&1; then
    STATUS=$(gcloud container clusters describe "$CLUSTER_NAME" --zone="$ZONE" --format='value(status)')
    NODES=$(gcloud container clusters describe "$CLUSTER_NAME" --zone="$ZONE" --format='value(currentNodeCount)')
    echo -e "${GREEN}[✔] Cluster '$CLUSTER_NAME' is ${STATUS} with ${NODES} nodes in ${ZONE}.${NC}"
else
    echo -e "${RED}[✘] Cluster '$CLUSTER_NAME' not found in ${ZONE}!${NC}"
fi

# Check Deployment
echo -e "\n${YELLOW}--- 2. Checking hello-app Deployment ---${NC}"
if kubectl get deployment hello-app >/dev/null 2>&1; then
    READY=$(kubectl get deployment hello-app -o jsonpath='{.status.readyReplicas}')
    DESIRED=$(kubectl get deployment hello-app -o jsonpath='{.spec.replicas}')
    echo -e "${GREEN}[✔] Deployment hello-app: ${READY}/${DESIRED} replicas ready.${NC}"
    kubectl get pods -l app=hello-app -o wide
else
    echo -e "${RED}[✘] Deployment hello-app not found!${NC}"
fi

# Check Service
echo -e "\n${YELLOW}--- 3. Checking LoadBalancer Service ---${NC}"
if kubectl get service hello-app >/dev/null 2>&1; then
    SVC_TYPE=$(kubectl get service hello-app -o jsonpath='{.spec.type}')
    EXT_IP=$(kubectl get service hello-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "<pending>")
    echo -e "${GREEN}[✔] Service hello-app (${SVC_TYPE}) External IP: ${EXT_IP}${NC}"
    if [ "$EXT_IP" != "<pending>" ] && [ -n "$EXT_IP" ]; then
        echo -e "${CYAN}Testing HTTP response from http://${EXT_IP}:${NC}"
        curl -s --connect-timeout 5 "http://${EXT_IP}" || true
        echo ""
    fi
else
    echo -e "${RED}[✘] Service hello-app not found!${NC}"
fi

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${GREEN}[✔] Verification completed.${NC}"
echo -e "${GREEN}====================================================================${NC}"
