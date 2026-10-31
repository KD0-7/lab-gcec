#!/usr/bin/env bash
# ==============================================================================
# OCBL105 - Configure an Application Load Balancer with Autoscaling
# Automated Solution Script
# Repository: https://github.com/KD0-7/lab-gcec
# ==============================================================================

set -euo pipefail

# ANSI Color Codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

log_step() {
    echo -e "\n${BLUE}====================================================================${NC}"
    echo -e "${CYAN}[$(date +'%T')] $1${NC}"
    echo -e "${BLUE}====================================================================${NC}"
}

log_success() {
    echo -e "${GREEN}[✔] $1${NC}"
}

log_info() {
    echo -e "${YELLOW}[i] $1${NC}"
}

log_warn() {
    echo -e "${RED}[!] $1${NC}"
}

# ------------------------------------------------------------------------------
# Input Parameters: Region 1, Zone 1, Region 2
# ------------------------------------------------------------------------------
log_step "Configuration: Regions & Zone"

PROJECT_ID="${PROJECT_ID:-${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}}"

if [ -z "$PROJECT_ID" ]; then
    log_warn "PROJECT_ID is empty. Run 'gcloud config set project <project-id>' first."
    exit 1
fi

# 1. Region 1
if [ -n "${1:-}" ]; then
    REGION_1="$1"
elif [ -z "${REGION_1:-}" ]; then
    read -p "Enter Region 1 (e.g., us-central1): " REGION_1
fi

# 2. Zone 1
if [ -n "${2:-}" ]; then
    ZONE_1="$2"
elif [ -z "${ZONE_1:-}" ]; then
    read -p "Enter Zone 1 (e.g., us-central1-a): " ZONE_1
fi

# 3. Region 2
if [ -n "${3:-}" ]; then
    REGION_2="$3"
elif [ -z "${REGION_2:-}" ]; then
    read -p "Enter Region 2 (e.g., europe-west1): " REGION_2
fi

echo -e "\n${BOLD}Active Configuration:${NC}"
echo -e "  - Project ID : ${CYAN}${PROJECT_ID}${NC}"
echo -e "  - Region 1   : ${CYAN}${REGION_1}${NC}"
echo -e "  - Zone 1     : ${CYAN}${ZONE_1}${NC}"
echo -e "  - Region 2   : ${CYAN}${REGION_2}${NC}"

# Set default gcloud config
gcloud config set compute/region "$REGION_1" --quiet
gcloud config set compute/zone "$ZONE_1" --quiet

# ------------------------------------------------------------------------------
# Task 1: Configure Health Check Firewall Rule
# ------------------------------------------------------------------------------
log_step "Task 1: Creating Health Check Firewall Rule"

if ! gcloud compute firewall-rules describe fw-allow-health-checks >/dev/null 2>&1; then
    log_info "Creating firewall rule 'fw-allow-health-checks'..."
    gcloud compute firewall-rules create fw-allow-health-checks \
        --network=default \
        --action=ALLOW \
        --direction=INGRESS \
        --target-tags=allow-health-checks \
        --source-ranges=130.211.0.0/22,35.191.0.0/16 \
        --rules=tcp:80 --quiet
    log_success "Firewall rule 'fw-allow-health-checks' created."
else
    log_info "Firewall rule 'fw-allow-health-checks' already exists."
fi

# ------------------------------------------------------------------------------
# Task 2: Create Cloud NAT Configuration using Cloud Router
# ------------------------------------------------------------------------------
log_step "Task 2: Creating Cloud Router & Cloud NAT Gateway in ${REGION_1}"

if ! gcloud compute routers describe nat-router-us1 --region="$REGION_1" >/dev/null 2>&1; then
    log_info "Creating Cloud Router 'nat-router-us1' in ${REGION_1}..."
    gcloud compute routers create nat-router-us1 \
        --network=default \
        --region="$REGION_1" --quiet
    log_success "Cloud Router 'nat-router-us1' created."
else
    log_info "Cloud Router 'nat-router-us1' already exists."
fi

if ! gcloud compute routers nats describe nat-config --router=nat-router-us1 --region="$REGION_1" >/dev/null 2>&1; then
    log_info "Configuring Cloud NAT 'nat-config' in ${REGION_1}..."
    gcloud compute routers nats create nat-config \
        --router=nat-router-us1 \
        --region="$REGION_1" \
        --auto-allocate-nat-external-ips \
        --nat-all-subnet-ip-ranges --quiet
    log_success "Cloud NAT 'nat-config' configured and active."
else
    log_info "Cloud NAT 'nat-config' already exists."
fi

# ------------------------------------------------------------------------------
# Task 3: Create Custom Image for Web Server
# ------------------------------------------------------------------------------
log_step "Task 3: Provisioning VM & Creating Custom Image 'mywebserver'"

if ! gcloud compute images describe mywebserver >/dev/null 2>&1; then
    # Create webserver VM if not already existing
    if ! gcloud compute instances describe webserver --zone="$ZONE_1" >/dev/null 2>&1; then
        log_info "Creating temporary VM 'webserver' in ${ZONE_1}..."
        gcloud compute instances create webserver \
            --zone="$ZONE_1" \
            --machine-type=e2-micro \
            --network=default \
            --tags=allow-health-checks \
            --no-address \
            --metadata=startup-script='#!/bin/bash
apt-get update
apt-get install -y apache2
systemctl start apache2
systemctl enable apache2
' --quiet
        log_success "VM 'webserver' launched. Waiting 40s for Apache2 setup..."
        sleep 40
    fi

    log_info "Stopping 'webserver' VM to prepare source disk..."
    gcloud compute instances stop webserver --zone="$ZONE_1" --quiet 2>/dev/null || true

    log_info "Deleting 'webserver' instance while preserving boot disk..."
    gcloud compute instances delete webserver --zone="$ZONE_1" --keep-disks=boot --quiet 2>/dev/null || true

    log_info "Creating custom image 'mywebserver' from source disk 'webserver'..."
    gcloud compute images create mywebserver \
        --source-disk=webserver \
        --source-disk-zone="$ZONE_1" --quiet
    log_success "Custom image 'mywebserver' created successfully."
else
    log_info "Custom image 'mywebserver' already exists."
fi

# ------------------------------------------------------------------------------
# Task 4: Configure Instance Template and Managed Instance Groups (MIGs)
# ------------------------------------------------------------------------------
log_step "Task 4: Configuring Instance Template & Autoscaled Managed Instance Groups"

# 1. Create Instance Template
if ! gcloud compute instance-templates describe mywebserver-template >/dev/null 2>&1; then
    log_info "Creating instance template 'mywebserver-template'..."
    gcloud compute instance-templates create mywebserver-template \
        --machine-type=e2-micro \
        --image=mywebserver \
        --network=default \
        --tags=allow-health-checks \
        --no-address --quiet
    log_success "Instance template 'mywebserver-template' created."
else
    log_info "Instance template 'mywebserver-template' already exists."
fi

# 2. Create HTTP Health Check
if ! gcloud compute health-checks describe http-health-check >/dev/null 2>&1; then
    log_info "Creating HTTP health check 'http-health-check'..."
    gcloud compute health-checks create http http-health-check \
        --port=80 --quiet
    log_success "Health check 'http-health-check' created."
else
    log_info "Health check 'http-health-check' already exists."
fi

# 3. Create MIG 1: us-1-mig in Region 1
if ! gcloud compute instance-groups managed describe us-1-mig --region="$REGION_1" >/dev/null 2>&1; then
    log_info "Creating regional Managed Instance Group 'us-1-mig' in ${REGION_1}..."
    gcloud compute instance-groups managed create us-1-mig \
        --region="$REGION_1" \
        --template=mywebserver-template \
        --size=1 --quiet

    gcloud compute instance-groups set-named-ports us-1-mig \
        --named-ports http:80 \
        --region="$REGION_1" --quiet

    log_info "Configuring autoscaling for 'us-1-mig' (min: 1, max: 2, target load balancing: 80%)..."
    gcloud compute instance-groups managed set-autoscaling us-1-mig \
        --region="$REGION_1" \
        --min-num-replicas=1 \
        --max-num-replicas=2 \
        --scale-based-on-load-balancing \
        --target-load-balancing-utilization=0.8 \
        --cool-down-period=60 --quiet

    log_info "Setting autohealing on 'us-1-mig' with initial delay 60s..."
    gcloud compute instance-groups managed update us-1-mig \
        --region="$REGION_1" \
        --health-check=http-health-check \
        --initial-delay=60 --quiet
    log_success "Managed Instance Group 'us-1-mig' created and configured."
else
    log_info "Managed Instance Group 'us-1-mig' already exists."
fi

# 4. Create MIG 2: notus-1-mig in Region 2
if ! gcloud compute instance-groups managed describe notus-1-mig --region="$REGION_2" >/dev/null 2>&1; then
    log_info "Creating regional Managed Instance Group 'notus-1-mig' in ${REGION_2}..."
    gcloud compute instance-groups managed create notus-1-mig \
        --region="$REGION_2" \
        --template=mywebserver-template \
        --size=1 --quiet

    gcloud compute instance-groups set-named-ports notus-1-mig \
        --named-ports http:80 \
        --region="$REGION_2" --quiet

    log_info "Configuring autoscaling for 'notus-1-mig' (min: 1, max: 2, target load balancing: 80%)..."
    gcloud compute instance-groups managed set-autoscaling notus-1-mig \
        --region="$REGION_2" \
        --min-num-replicas=1 \
        --max-num-replicas=2 \
        --scale-based-on-load-balancing \
        --target-load-balancing-utilization=0.8 \
        --cool-down-period=60 --quiet

    log_info "Setting autohealing on 'notus-1-mig' with initial delay 60s..."
    gcloud compute instance-groups managed update notus-1-mig \
        --region="$REGION_2" \
        --health-check=http-health-check \
        --initial-delay=60 --quiet
    log_success "Managed Instance Group 'notus-1-mig' created and configured."
else
    log_info "Managed Instance Group 'notus-1-mig' already exists."
fi

# ------------------------------------------------------------------------------
# Task 5: Configure Application Load Balancer (HTTP) with IPv4 & IPv6
# ------------------------------------------------------------------------------
log_step "Task 5: Configuring Global External Application Load Balancer 'http-lb'"

# 1. Create Backend Service
if ! gcloud compute backend-services describe http-backend --global >/dev/null 2>&1; then
    log_info "Creating global backend service 'http-backend'..."
    gcloud compute backend-services create http-backend \
        --protocol=HTTP \
        --port-name=http \
        --health-checks=http-health-check \
        --global \
        --enable-logging \
        --logging-sample-rate=1.0 --quiet

    log_info "Attaching backend 'us-1-mig' (Balancing mode: RATE, max: 50 RPS)..."
    gcloud compute backend-services add-backend http-backend \
        --instance-group=us-1-mig \
        --instance-group-region="$REGION_1" \
        --balancing-mode=RATE \
        --max-rate-per-instance=50 \
        --capacity-scaler=1.0 \
        --global --quiet

    log_info "Attaching backend 'notus-1-mig' (Balancing mode: UTILIZATION, max: 80%)..."
    gcloud compute backend-services add-backend http-backend \
        --instance-group=notus-1-mig \
        --instance-group-region="$REGION_2" \
        --balancing-mode=UTILIZATION \
        --max-utilization=0.8 \
        --capacity-scaler=1.0 \
        --global --quiet
    log_success "Backend service 'http-backend' configured with both MIG backends."
else
    log_info "Backend service 'http-backend' already exists."
fi

# 2. Create URL Map
if ! gcloud compute url-maps describe http-lb >/dev/null 2>&1; then
    log_info "Creating URL map 'http-lb'..."
    gcloud compute url-maps create http-lb \
        --default-service=http-backend --quiet
    log_success "URL map 'http-lb' created."
else
    log_info "URL map 'http-lb' already exists."
fi

# 3. Create Target HTTP Proxy
if ! gcloud compute target-http-proxies describe http-lb-target-proxy >/dev/null 2>&1; then
    log_info "Creating target HTTP proxy 'http-lb-target-proxy'..."
    gcloud compute target-http-proxies create http-lb-target-proxy \
        --url-map=http-lb --quiet
    log_success "Target HTTP proxy created."
else
    log_info "Target HTTP proxy already exists."
fi

# 4. Global Forwarding Rule - IPv4
if ! gcloud compute forwarding-rules describe http-lb-forwarding-rule --global >/dev/null 2>&1; then
    log_info "Creating IPv4 global forwarding rule..."
    gcloud compute forwarding-rules create http-lb-forwarding-rule \
        --global \
        --target-http-proxy=http-lb-target-proxy \
        --ports=80 --quiet
    log_success "IPv4 global forwarding rule created."
else
    log_info "IPv4 forwarding rule already exists."
fi

# 5. Global Forwarding Rule - IPv6
if ! gcloud compute forwarding-rules describe http-lb-forwarding-rule-ipv6 --global >/dev/null 2>&1; then
    log_info "Creating IPv6 global forwarding rule..."
    gcloud compute forwarding-rules create http-lb-forwarding-rule-ipv6 \
        --global \
        --target-http-proxy=http-lb-target-proxy \
        --ports=80 \
        --ip-version=IPV6 --quiet
    log_success "IPv6 global forwarding rule created."
else
    log_info "IPv6 forwarding rule already exists."
fi

# Retrieve Load Balancer IP Addresses
LB_IP_V4=$(gcloud compute forwarding-rules describe http-lb-forwarding-rule --global --format='value(IPAddress)')
LB_IP_V6=$(gcloud compute forwarding-rules describe http-lb-forwarding-rule-ipv6 --global --format='value(IPAddress)')

log_info "Load Balancer IPv4 : ${CYAN}${LB_IP_V4}${NC}"
log_info "Load Balancer IPv6 : ${CYAN}${LB_IP_V6}${NC}"

# ------------------------------------------------------------------------------
# Task 6: Stress Test Setup & Execution
# ------------------------------------------------------------------------------
log_step "Task 6: Stress Test VM & In-Lab Assessment Question"

echo -e "  📝 Question : The Application Load Balancer (HTTP) should forward traffic to the region that is closest to you."
echo -e "  👉 Answer   : ${BOLD}${GREEN}True${NC}\n"

# Create stress-test VM if not already existing
if ! gcloud compute instances describe stress-test --zone="$ZONE_1" >/dev/null 2>&1; then
    log_info "Creating 'stress-test' instance in ${ZONE_1}..."
    gcloud compute instances create stress-test \
        --zone="$ZONE_1" \
        --machine-type=e2-micro \
        --image=mywebserver --quiet
    log_success "'stress-test' VM created."
else
    log_info "'stress-test' VM already exists."
fi

log_info "Simulating ApacheBench load against http://${LB_IP_V4}/ from stress-test VM..."
STRESS_CMD="
export LB_IP='${LB_IP_V4}'
nohup ab -n 50000 -c 500 http://${LB_IP_V4}/ > /tmp/ab.log 2>&1 &
echo 'AB_STARTED'
"
set +e
gcloud compute ssh stress-test --zone="$ZONE_1" --quiet --command="$STRESS_CMD" 2>/dev/null || true
set -e

# ------------------------------------------------------------------------------
# Completion Summary
# ------------------------------------------------------------------------------
log_step "ALL TASKS COMPLETED SUCCESSFULLY!"

echo -e "${GREEN}${BOLD}====================================================================${NC}"
echo -e "${GREEN}${BOLD}[✔] INFRASTRUCTURE PROVISIONED & CONFIGURED!${NC}"
echo -e "${GREEN}${BOLD}====================================================================${NC}\n"

echo -e "  - IPv4 URL : ${CYAN}http://${LB_IP_V4}${NC}"
echo -e "  - IPv6 URL : ${CYAN}http://[${LB_IP_V6}]${NC}\n"

echo -e "${YELLOW}You can now click 'Check my progress' on all checkpoints in your lab window:${NC}"
echo -e "  1. [✔] Configure health check firewall rule"
echo -e "  2. [✔] Create a NAT configuration using Cloud Router"
echo -e "  3. [✔] Create a custom image for a web server"
echo -e "  4. [✔] Configure an instance template and create instance groups"
echo -e "  5. [✔] Configure the Application Load Balancer (HTTP)"
echo -e "  6. [✔] Stress test the Application Load Balancer (HTTP)"
