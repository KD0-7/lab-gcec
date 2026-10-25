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

# Target zone: CLI arg > Environment Variable > Default (europe-west1-c)
TARGET_ZONE="${1:-${ZONE:-europe-west1-c}}"

echo -e "${YELLOW}[i] Enabling Compute Engine and Deployment Manager APIs if needed...${NC}"
gcloud services enable compute.googleapis.com deploymentmanager.googleapis.com --quiet

echo -e "${YELLOW}[i] Searching for lamp-1-vm (target zone: ${TARGET_ZONE})...${NC}"

VM_EXISTS=false
ZONE="$TARGET_ZONE"

for i in {1..30}; do
    # 1. Check if VM exists in target zone
    if gcloud compute instances describe lamp-1-vm --zone="$ZONE" >/dev/null 2>&1; then
        VM_EXISTS=true
        break
    fi

    # 2. If not found in target zone, auto-detect across all zones
    DETECTED_ZONE=$(gcloud compute instances list --filter="name=lamp-1-vm" --format='value(zone)' 2>/dev/null | head -n1 || true)
    if [ -n "$DETECTED_ZONE" ]; then
        ZONE="$DETECTED_ZONE"
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
    echo -e "${YELLOW}Deployment steps:${NC}"
    echo -e "  1. Console > Marketplace > Search 'LAMP' > Click 'LAMP Stack, by Google Click to Deploy'"
    echo -e "  2. Click 'Get Started' > Accept Terms > Click 'Deploy'"
    echo -e "  3. Set Zone to '${ZONE}', Series to 'E2', Machine Type to 'e2-medium' > Click 'Deploy'"
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
for i in {1..20}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://${EXTERNAL_IP}" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        HTTP_READY=true
        echo -e "${GREEN}[✔] Apache HTTP Server returned HTTP status: ${HTTP_CODE}${NC}"
        break
    fi
    echo -n "."
    sleep 3
done
echo ""

if [ "$HTTP_READY" = true ]; then
    echo -e "\n${GREEN}====================================================================${NC}"
    echo -e "${GREEN}[✔] LAMP STACK IS FULLY OPERATIONAL!${NC}"
    echo -e "${CYAN}Site URL: http://${EXTERNAL_IP}${NC}"
    echo -e "${GREEN}====================================================================${NC}"
    echo -e "${YELLOW}In-Lab Quiz Reminder:${NC}"
    echo -e "  Question: Which tool is used to deploy Google Cloud Marketplace solutions like the LAMP Stack?"
    echo -e "  Answer  : ${GREEN}Deployment Manager${NC}"
    echo -e "${YELLOW}You can now click 'Check my progress' on the lab page to score 100/100!${NC}"
else
    echo -e "${YELLOW}[!] Apache is still starting up. Wait 20 seconds and refresh your browser at: http://${EXTERNAL_IP}${NC}"
fi
