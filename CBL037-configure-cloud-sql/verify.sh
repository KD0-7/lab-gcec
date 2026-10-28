#!/usr/bin/env bash
# ==============================================================================
# CBL037 - Configure Cloud SQL
# Verification & Health Check Script
# Repository: https://github.com/KD0-7/lab-gcec
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}====================================================================${NC}"
echo -e "${CYAN}CBL037: Cloud SQL & Application Verification${NC}"
echo -e "${BLUE}====================================================================${NC}"

INSTANCE_NAME="wordpress-db"
DB_NAME="wordpress"

# 1. Cloud SQL Instance Verification
echo -e "\n${YELLOW}--- 1. Checking Cloud SQL Instance '${INSTANCE_NAME}' ---${NC}"
if gcloud sql instances describe "$INSTANCE_NAME" >/dev/null 2>&1; then
    STATE=$(gcloud sql instances describe "$INSTANCE_NAME" --format='value(state)')
    TIER=$(gcloud sql instances describe "$INSTANCE_NAME" --format='value(settings.tier)')
    REGION=$(gcloud sql instances describe "$INSTANCE_NAME" --format='value(region)')
    GCE_ZONE=$(gcloud sql instances describe "$INSTANCE_NAME" --format='value(gceZone)')
    CONN_NAME=$(gcloud sql instances describe "$INSTANCE_NAME" --format='value(connectionName)')
    PUB_IP=$(gcloud sql instances describe "$INSTANCE_NAME" --format='value(ipAddresses.filter(type:PRIMARY).ipAddress)')
    PRIV_IP=$(gcloud sql instances describe "$INSTANCE_NAME" --format='value(ipAddresses.filter(type:PRIVATE).ipAddress)')

    echo -e "${GREEN}[✔] Instance '${INSTANCE_NAME}' exists!${NC}"
    echo -e "    - Status          : ${GREEN}${STATE}${NC}"
    echo -e "    - Region / Zone   : ${CYAN}${REGION} / ${GCE_ZONE}${NC}"
    echo -e "    - Machine Tier    : ${CYAN}${TIER}${NC}"
    echo -e "    - Connection Name : ${CYAN}${CONN_NAME}${NC}"
    echo -e "    - Public IP       : ${CYAN}${PUB_IP:-None}${NC}"
    echo -e "    - Private IP      : ${CYAN}${PRIV_IP:-None}${NC}"
else
    echo -e "${RED}[✘] Cloud SQL instance '${INSTANCE_NAME}' not found!${NC}"
fi

# 2. Database Verification
echo -e "\n${YELLOW}--- 2. Checking Database '${DB_NAME}' ---${NC}"
if gcloud sql databases describe "$DB_NAME" --instance="$INSTANCE_NAME" >/dev/null 2>&1; then
    echo -e "${GREEN}[✔] Database '${DB_NAME}' exists on instance '${INSTANCE_NAME}'.${NC}"
else
    echo -e "${RED}[✘] Database '${DB_NAME}' not found on instance '${INSTANCE_NAME}'!${NC}"
fi

# 3. Virtual Machines & Proxy Status
echo -e "\n${YELLOW}--- 3. Checking Compute Engine Instances & Cloud SQL Proxy ---${NC}"
PROXY_ZONE=$(gcloud compute instances list --filter="name=wordpress-proxy" --format='value(zone)' 2>/dev/null | head -n1 || true)
if [ -n "$PROXY_ZONE" ]; then
    PROXY_EXT_IP=$(gcloud compute instances describe wordpress-proxy --zone="$PROXY_ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
    echo -e "${GREEN}[✔] VM 'wordpress-proxy' (${PROXY_ZONE}) found: http://${PROXY_EXT_IP}${NC}"

    # Check proxy process via SSH
    set +e
    PROXY_CHECK=$(gcloud compute ssh wordpress-proxy --zone="$PROXY_ZONE" --quiet --command="pgrep -f cloud_sql_proxy || true" 2>/dev/null)
    set -e
    if [ -n "$PROXY_CHECK" ]; then
        echo -e "${GREEN}[✔] Cloud SQL Proxy process is active on wordpress-proxy (PID: ${PROXY_CHECK}).${NC}"
    else
        echo -e "${YELLOW}[!] Cloud SQL Proxy process not detected running via SSH. Verify via console or start manually.${NC}"
    fi
else
    echo -e "${RED}[✘] VM 'wordpress-proxy' not found.${NC}"
fi

PRIV_ZONE=$(gcloud compute instances list --filter="name=wordpress-private-ip" --format='value(zone)' 2>/dev/null | head -n1 || true)
if [ -n "$PRIV_ZONE" ]; then
    PRIV_EXT_IP=$(gcloud compute instances describe wordpress-private-ip --zone="$PRIV_ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
    echo -e "${GREEN}[✔] VM 'wordpress-private-ip' (${PRIV_ZONE}) found: http://${PRIV_EXT_IP}${NC}"
else
    echo -e "${RED}[✘] VM 'wordpress-private-ip' not found.${NC}"
fi

echo -e "\n${BLUE}====================================================================${NC}"
echo -e "${GREEN}[✔] Verification completed. Ready to score!${NC}"
echo -e "${BLUE}====================================================================${NC}"
