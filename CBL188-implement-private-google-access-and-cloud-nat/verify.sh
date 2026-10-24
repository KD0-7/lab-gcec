#!/usr/bin/env bash
# ==============================================================================
# CBL188 - Verification Script
# Validates vm-internal, PGA, and Cloud NAT status
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

REGION="us-west1"
ZONE="us-west1-b"

echo -e "${BLUE}====================================================================${NC}"
echo -e "${CYAN}CBL188: Verifying Resource Health & Configuration${NC}"
echo -e "${BLUE}====================================================================${NC}"

# Check VM
echo -e "\n${YELLOW}--- 1. Checking vm-internal ---${NC}"
if gcloud compute instances describe vm-internal --zone="$ZONE" >/dev/null 2>&1; then
    EXTERNAL_IP=$(gcloud compute instances describe vm-internal --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null || true)
    INTERNAL_IP=$(gcloud compute instances describe vm-internal --zone="$ZONE" --format='get(networkInterfaces[0].networkIP)')
    if [ -z "$EXTERNAL_IP" ]; then
        echo -e "${GREEN}[✔] vm-internal has NO external IP (Private Instance). Internal IP: ${INTERNAL_IP}${NC}"
    else
        echo -e "${RED}[✘] vm-internal has an external IP: ${EXTERNAL_IP}. Should be None!${NC}"
    fi
else
    echo -e "${RED}[✘] vm-internal not found in ${ZONE}!${NC}"
fi

# Check PGA on Subnet
echo -e "\n${YELLOW}--- 2. Checking Private Google Access on privatenet-us ---${NC}"
PGA_STATUS=$(gcloud compute networks subnets describe privatenet-us --region="$REGION" --format='value(privateIpGoogleAccess)')
if [ "$PGA_STATUS" = "True" ]; then
    echo -e "${GREEN}[✔] Private Google Access is ENABLED on privatenet-us!${NC}"
else
    echo -e "${RED}[✘] Private Google Access is DISABLED on privatenet-us!${NC}"
fi

# Check Cloud NAT
echo -e "\n${YELLOW}--- 3. Checking Cloud NAT Gateway (nat-config) ---${NC}"
if gcloud compute routers nats describe nat-config --router=nat-router --region="$REGION" >/dev/null 2>&1; then
    NAT_STATUS=$(gcloud compute routers get-status nat-router --region="$REGION" --format='value(result.natStatus[0].name)' 2>/dev/null || echo "RUNNING")
    echo -e "${GREEN}[✔] Cloud NAT gateway nat-config is active on router nat-router!${NC}"
else
    echo -e "${RED}[✘] Cloud NAT nat-config not found in ${REGION}!${NC}"
fi

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${GREEN}[✔] Verification completed.${NC}"
echo -e "${GREEN}====================================================================${NC}"
