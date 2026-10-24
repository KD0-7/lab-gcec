#!/usr/bin/env bash
# ==============================================================================
# CBL138 - Verification Script
# Validates VM, Service Account, Storage Buckets & Nginx Status
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
ZONE="us-east1-c"
BUCKET1="${PROJECT_ID}-bucket1"
BUCKET2="${PROJECT_ID}-bucket2"

echo -e "${BLUE}====================================================================${NC}"
echo -e "${CYAN}CBL138: Verifying Resource Health & Configuration${NC}"
echo -e "${BLUE}====================================================================${NC}"

# Check VM
echo -e "\n${YELLOW}--- 1. Checking VM Instance (first-vm) ---${NC}"
if gcloud compute instances describe first-vm --zone="$ZONE" >/dev/null 2>&1; then
    VM_STATUS=$(gcloud compute instances describe first-vm --zone="$ZONE" --format='value(status)')
    VM_IP=$(gcloud compute instances describe first-vm --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
    echo -e "${GREEN}[✔] first-vm exists and is ${VM_STATUS}. External IP: ${VM_IP}${NC}"
else
    echo -e "${RED}[✘] first-vm not found in ${ZONE}!${NC}"
fi

# Check Service Account
echo -e "\n${YELLOW}--- 2. Checking IAM Service Account (test-service-account) ---${NC}"
SA_EMAIL="test-service-account@${PROJECT_ID}.iam.gserviceaccount.com"
if gcloud iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1; then
    echo -e "${GREEN}[✔] Service account ${SA_EMAIL} exists!${NC}"
else
    echo -e "${RED}[✘] Service account ${SA_EMAIL} not found!${NC}"
fi

# Check Buckets
echo -e "\n${YELLOW}--- 3. Checking Cloud Storage Buckets ---${NC}"
if gcloud storage buckets describe "gs://${BUCKET1}" >/dev/null 2>&1; then
    echo -e "${GREEN}[✔] Bucket gs://${BUCKET1} exists!${NC}"
else
    echo -e "${RED}[✘] Bucket gs://${BUCKET1} not found!${NC}"
fi

if gcloud storage buckets describe "gs://${BUCKET2}" >/dev/null 2>&1; then
    echo -e "${GREEN}[✔] Bucket gs://${BUCKET2} exists!${NC}"
else
    echo -e "${RED}[✘] Bucket gs://${BUCKET2} not found!${NC}"
fi

# Check Nginx HTTP response
echo -e "\n${YELLOW}--- 4. Checking Nginx Web Server HTTP Response ---${NC}"
if [ -n "${VM_IP:-}" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://${VM_IP}" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}[✔] Nginx web server returned HTTP status 200 OK!${NC}"
        echo -e "${CYAN}Preview URL: http://${VM_IP}${NC}"
    else
        echo -e "${YELLOW}[!] HTTP response code: ${HTTP_CODE}. Nginx may still be starting up.${NC}"
    fi
fi

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${GREEN}[✔] Verification completed.${NC}"
echo -e "${GREEN}====================================================================${NC}"
