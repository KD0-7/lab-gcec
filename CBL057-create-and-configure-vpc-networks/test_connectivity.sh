#!/usr/bin/env bash
# ==============================================================================
# CBL057 - Connectivity Verification Script
# Tests public external ping & internal VPC ping
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}====================================================================${NC}"
echo -e "${CYAN}Task 4: Testing Network Connectivity Across VPC Networks${NC}"
echo -e "${BLUE}====================================================================${NC}"

# Fetch IPs
MYNET_NOTUS_EXT=$(gcloud compute instances describe mynet-notus-vm --zone=asia-southeast1-c --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
MGMT_US_EXT=$(gcloud compute instances describe managementnet-us-vm --zone=us-east1-c --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
PRIVATE_US_EXT=$(gcloud compute instances describe privatenet-us-vm --zone=us-east1-c --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

MYNET_NOTUS_INT=$(gcloud compute instances describe mynet-notus-vm --zone=asia-southeast1-c --format='get(networkInterfaces[0].networkIP)')
MGMT_US_INT=$(gcloud compute instances describe managementnet-us-vm --zone=us-east1-c --format='get(networkInterfaces[0].networkIP)')
PRIVATE_US_INT=$(gcloud compute instances describe privatenet-us-vm --zone=us-east1-c --format='get(networkInterfaces[0].networkIP)')

echo -e "\n${YELLOW}--- 1. Testing External IP Connectivity (via Public Internet) ---${NC}"
echo -e "Pinging mynet-notus-vm external IP (${MYNET_NOTUS_EXT})..."
ping -c 2 "$MYNET_NOTUS_EXT" && echo -e "${GREEN}[✔] SUCCESS: External ping to mynet-notus-vm works!${NC}" || true

echo -e "Pinging managementnet-us-vm external IP (${MGMT_US_EXT})..."
ping -c 2 "$MGMT_US_EXT" && echo -e "${GREEN}[✔] SUCCESS: External ping to managementnet-us-vm works!${NC}" || true

echo -e "Pinging privatenet-us-vm external IP (${PRIVATE_US_EXT})..."
ping -c 2 "$PRIVATE_US_EXT" && echo -e "${GREEN}[✔] SUCCESS: External ping to privatenet-us-vm works!${NC}" || true

echo -e "\n${YELLOW}--- 2. Testing Internal IP Connectivity from mynet-us-vm ---${NC}"
echo -e "Running SSH tunnel through IAP to ping internal IPs from mynet-us-vm..."

gcloud compute ssh mynet-us-vm --zone=us-east1-c --tunnel-through-iap --command="
echo '=== Internal Ping to mynet-notus-vm (Same VPC: mynetwork) ==='
ping -c 2 ${MYNET_NOTUS_INT} && echo '[✔] Intra-VPC Ping SUCCESSFUL!' || echo '[✘] FAILED'

echo '=== Internal Ping to managementnet-us-vm (Different VPC: managementnet) ==='
ping -c 2 -W 2 ${MGMT_US_INT} || echo '[✔] 100% packet loss as expected (VPC isolation working)!'

echo '=== Internal Ping to privatenet-us-vm (Different VPC: privatenet) ==='
ping -c 2 -W 2 ${PRIVATE_US_INT} || echo '[✔] 100% packet loss as expected (VPC isolation working)!'
" || true

echo -e "\n${GREEN}[✔] Connectivity verification complete!${NC}"
