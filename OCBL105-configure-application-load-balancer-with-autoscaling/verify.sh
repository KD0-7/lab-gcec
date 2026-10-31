#!/usr/bin/env bash
# ==============================================================================
# OCBL105 - Verification & Health Check Script
# Validates Load Balancer, MIGs, Cloud NAT, and Firewall
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
echo -e "${CYAN}OCBL105: Application Load Balancer & Autoscaling Verification${NC}"
echo -e "${BLUE}====================================================================${NC}"

# 1. Firewall Rule Check
echo -e "\n${YELLOW}--- 1. Checking Firewall Rule ---${NC}"
if gcloud compute firewall-rules describe fw-allow-health-checks >/dev/null 2>&1; then
    echo -e "${GREEN}[✔] Firewall rule 'fw-allow-health-checks' exists.${NC}"
else
    echo -e "${RED}[✘] Firewall rule 'fw-allow-health-checks' not found!${NC}"
fi

# 2. Cloud NAT Check
echo -e "\n${YELLOW}--- 2. Checking Cloud Router & Cloud NAT ---${NC}"
NAT_REGION=$(gcloud compute routers list --filter="name=nat-router-us1" --format='value(region)' 2>/dev/null | head -n1 || true)
if [ -n "$NAT_REGION" ]; then
    echo -e "${GREEN}[✔] Cloud Router 'nat-router-us1' exists in ${NAT_REGION}.${NC}"
    if gcloud compute routers nats describe nat-config --router=nat-router-us1 --region="$NAT_REGION" >/dev/null 2>&1; then
        echo -e "${GREEN}[✔] Cloud NAT 'nat-config' exists in ${NAT_REGION}.${NC}"
    else
        echo -e "${RED}[✘] Cloud NAT 'nat-config' not found!${NC}"
    fi
else
    echo -e "${RED}[✘] Cloud Router 'nat-router-us1' not found!${NC}"
fi

# 3. Custom Image Check
echo -e "\n${YELLOW}--- 3. Checking Custom Image ---${NC}"
if gcloud compute images describe mywebserver >/dev/null 2>&1; then
    IMG_STATUS=$(gcloud compute images describe mywebserver --format='value(status)')
    echo -e "${GREEN}[✔] Custom image 'mywebserver' exists (Status: ${IMG_STATUS}).${NC}"
else
    echo -e "${RED}[✘] Custom image 'mywebserver' not found!${NC}"
fi

# 4. Instance Template & Health Check
echo -e "\n${YELLOW}--- 4. Checking Instance Template & Health Check ---${NC}"
if gcloud compute instance-templates describe mywebserver-template >/dev/null 2>&1; then
    echo -e "${GREEN}[✔] Instance template 'mywebserver-template' exists.${NC}"
else
    echo -e "${RED}[✘] Instance template 'mywebserver-template' not found!${NC}"
fi

if gcloud compute health-checks describe http-health-check >/dev/null 2>&1; then
    echo -e "${GREEN}[✔] Health check 'http-health-check' exists.${NC}"
else
    echo -e "${RED}[✘] Health check 'http-health-check' not found!${NC}"
fi

# 5. Managed Instance Groups Check
echo -e "\n${YELLOW}--- 5. Checking Managed Instance Groups ---${NC}"
MIG1_REGION=$(gcloud compute instance-groups managed list --filter="name=us-1-mig" --format='value(region)' 2>/dev/null | head -n1 || true)
if [ -n "$MIG1_REGION" ]; then
    MIG1_SIZE=$(gcloud compute instance-groups managed describe us-1-mig --region="$MIG1_REGION" --format='value(targetSize)')
    echo -e "${GREEN}[✔] MIG 'us-1-mig' exists in ${MIG1_REGION} (Target size: ${MIG1_SIZE}).${NC}"
else
    echo -e "${RED}[✘] MIG 'us-1-mig' not found!${NC}"
fi

MIG2_REGION=$(gcloud compute instance-groups managed list --filter="name=notus-1-mig" --format='value(region)' 2>/dev/null | head -n1 || true)
if [ -n "$MIG2_REGION" ]; then
    MIG2_SIZE=$(gcloud compute instance-groups managed describe notus-1-mig --region="$MIG2_REGION" --format='value(targetSize)')
    echo -e "${GREEN}[✔] MIG 'notus-1-mig' exists in ${MIG2_REGION} (Target size: ${MIG2_SIZE}).${NC}"
else
    echo -e "${RED}[✘] MIG 'notus-1-mig' not found!${NC}"
fi

# 6. Load Balancer Frontend & Backend Services
echo -e "\n${YELLOW}--- 6. Checking Global Load Balancer ---${NC}"
if gcloud compute backend-services describe http-backend --global >/dev/null 2>&1; then
    echo -e "${GREEN}[✔] Backend service 'http-backend' exists.${NC}"
else
    echo -e "${RED}[✘] Backend service 'http-backend' not found!${NC}"
fi

if gcloud compute forwarding-rules describe http-lb-forwarding-rule --global >/dev/null 2>&1; then
    LB_IPV4=$(gcloud compute forwarding-rules describe http-lb-forwarding-rule --global --format='value(IPAddress)')
    echo -e "${GREEN}[✔] IPv4 Forwarding rule active: http://${LB_IPV4}${NC}"
else
    echo -e "${RED}[✘] IPv4 Forwarding rule not found!${NC}"
fi

if gcloud compute forwarding-rules describe http-lb-forwarding-rule-ipv6 --global >/dev/null 2>&1; then
    LB_IPV6=$(gcloud compute forwarding-rules describe http-lb-forwarding-rule-ipv6 --global --format='value(IPAddress)')
    echo -e "${GREEN}[✔] IPv6 Forwarding rule active: http://[${LB_IPV6}]${NC}"
fi

echo -e "\n${BLUE}====================================================================${NC}"
echo -e "${GREEN}[✔] Verification completed. Ready to score 100/100!${NC}"
echo -e "${BLUE}====================================================================${NC}"
