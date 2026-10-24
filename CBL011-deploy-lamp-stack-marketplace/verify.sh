#!/usr/bin/env bash
# ==============================================================================
# CBL011 - Deploy a LAMP Stack with Google Cloud Marketplace
# Verification & Health Check Script
# Repository: https://github.com/KD0-7/lab-gcec
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}====================================================================${NC}"
echo -e "${CYAN}CBL011: Checking LAMP Stack Deployment Status${NC}"
echo -e "${BLUE}====================================================================${NC}"

ZONE="europe-west1-b"

echo -e "${YELLOW}[i] Enabling Compute Engine and Deployment Manager APIs if needed...${NC}"
gcloud services enable compute.googleapis.com deploymentmanager.googleapis.com --quiet

echo -e "${YELLOW}[i] Searching for lamp-1-vm in zone: ${ZONE}...${NC}"

VM_EXISTS=false
for i in {1..30}; do
    if gcloud compute instances describe lamp-1-vm --zone="$ZONE" >/dev/null 2>&1; then
        VM_EXISTS=true
        break
    fi
    echo -n "."
    sleep 4
done
echo ""

if [ "$VM_EXISTS" = false ]; then
    echo -e "${RED}[✘] lamp-1-vm not found in zone ${ZONE}.${NC}"
    echo -e "${YELLOW}Please ensure you deployed the LAMP Stack via Cloud Marketplace in zone ${ZONE}.${NC}"
    exit 1
fi

STATUS=$(gcloud compute instances describe lamp-1-vm --zone="$ZONE" --format='value(status)')
EXTERNAL_IP=$(gcloud compute instances describe lamp-1-vm --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
MACHINE_TYPE=$(gcloud compute instances describe lamp-1-vm --zone="$ZONE" --format='value(machineType)' | awk -F'/' '{print $NF}')

echo -e "${GREEN}[✔] Instance lamp-1-vm is found!${NC}"
echo -e "    - Status       : ${GREEN}${STATUS}${NC}"
echo -e "    - Zone         : ${CYAN}${ZONE}${NC}"
echo -e "    - Machine Type : ${CYAN}${MACHINE_TYPE}${NC}"
echo -e "    - External IP  : ${CYAN}${EXTERNAL_IP}${NC}"

echo -e "\n${YELLOW}[i] Testing Apache HTTP Server connectivity at http://${EXTERNAL_IP}...${NC}"

HTTP_READY=false
for i in {1..15}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://${EXTERNAL_IP}" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        HTTP_READY=true
        echo -e "${GREEN}[✔] Apache HTTP Server returned HTTP status: ${HTTP_CODE}${NC}"
        break
    fi
    sleep 3
done

if [ "$HTTP_READY" = true ]; then
    echo -e "\n${GREEN}====================================================================${NC}"
    echo -e "${GREEN}[✔] LAMP STACK IS FULLY OPERATIONAL!${NC}"
    echo -e "${CYAN}Site URL: http://${EXTERNAL_IP}${NC}"
    echo -e "${GREEN}====================================================================${NC}"
    echo -e "${YELLOW}You can now click 'Check my progress' on the lab page to score 100/100!${NC}"
else
    echo -e "${YELLOW}[!] Apache is still starting up. Wait 20 seconds and refresh your browser at: http://${EXTERNAL_IP}${NC}"
fi
