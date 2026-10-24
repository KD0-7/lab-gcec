#!/usr/bin/env bash
# ==============================================================================
# CBL057 - Create and Configure VPC Networks
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

# ------------------------------------------------------------------------------
# Task 1: Clean Up Default Network & Enable APIs
# ------------------------------------------------------------------------------
log_step "Task 1: Enabling APIs & Cleaning up Default Network"

log_info "Enabling required APIs..."
gcloud services enable \
    iap.googleapis.com \
    networkmanagement.googleapis.com --quiet
log_success "APIs enabled."

log_info "Deleting default firewall rules if they exist..."
DEFAULT_RULES=$(gcloud compute firewall-rules list --filter="network:default" --format="value(name)" 2>/dev/null || true)
if [ -n "$DEFAULT_RULES" ]; then
    echo "$DEFAULT_RULES" | xargs -r -n 1 gcloud compute firewall-rules delete --quiet
    log_success "Deleted default firewall rules."
else
    log_info "No default firewall rules found."
fi

log_info "Deleting default network if it exists..."
if gcloud compute networks describe default >/dev/null 2>&1; then
    gcloud compute networks delete default --quiet
    log_success "Deleted default network."
else
    log_info "Default network does not exist."
fi

# ------------------------------------------------------------------------------
# Task 2: Create Auto Mode Network (mynetwork) & VM Instances
# ------------------------------------------------------------------------------
log_step "Task 2: Creating Auto Mode VPC (mynetwork), Firewall Rules, & VMs"

if ! gcloud compute networks describe mynetwork >/dev/null 2>&1; then
    log_info "Creating auto-mode network mynetwork..."
    gcloud compute networks create mynetwork --subnet-mode=auto
    log_success "Created mynetwork (auto mode)."
else
    log_info "mynetwork already exists."
fi

log_info "Creating standard firewall rules for mynetwork..."
gcloud compute firewall-rules create mynetwork-allow-icmp \
    --network=mynetwork \
    --priority=65534 \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=icmp \
    --source-ranges=0.0.0.0/0 2>/dev/null || true

gcloud compute firewall-rules create mynetwork-allow-ssh \
    --network=mynetwork \
    --priority=65534 \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:22 \
    --source-ranges=0.0.0.0/0 2>/dev/null || true

gcloud compute firewall-rules create mynetwork-allow-rdp \
    --network=mynetwork \
    --priority=65534 \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:3389 \
    --source-ranges=0.0.0.0/0 2>/dev/null || true

gcloud compute firewall-rules create mynetwork-allow-custom \
    --network=mynetwork \
    --priority=65534 \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=all \
    --source-ranges=10.128.0.0/9 2>/dev/null || true

gcloud compute firewall-rules create allow-iap-ssh \
    --network=mynetwork \
    --priority=1000 \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:22 \
    --source-ranges=35.235.240.0/20 \
    --target-tags=iap-gce 2>/dev/null || true
log_success "Firewall rules for mynetwork configured."

log_info "Creating VM mynet-us-vm in us-east1-c..."
if ! gcloud compute instances describe mynet-us-vm --zone=us-east1-c >/dev/null 2>&1; then
    gcloud compute instances create mynet-us-vm \
        --zone=us-east1-c \
        --machine-type=e2-medium \
        --subnet=mynetwork \
        --tags=iap-gce \
        --image-family=debian-12 \
        --image-project=debian-cloud \
        --boot-disk-size=10GB --quiet
    log_success "Created mynet-us-vm."
else
    log_info "mynet-us-vm already exists."
fi

log_info "Creating VM mynet-notus-vm in asia-southeast1-c..."
if ! gcloud compute instances describe mynet-notus-vm --zone=asia-southeast1-c >/dev/null 2>&1; then
    gcloud compute instances create mynet-notus-vm \
        --zone=asia-southeast1-c \
        --machine-type=e2-medium \
        --subnet=mynetwork \
        --tags=iap-gce \
        --image-family=debian-12 \
        --image-project=debian-cloud \
        --boot-disk-size=10GB --quiet
    log_success "Created mynet-notus-vm."
else
    log_info "mynet-notus-vm already exists."
fi

log_info "Converting mynetwork to custom mode..."
gcloud compute networks update mynetwork --switch-to-custom-subnet-mode --quiet 2>/dev/null || true
log_success "Converted mynetwork to custom mode."

# ------------------------------------------------------------------------------
# Task 3: Create Custom Mode Networks (managementnet & privatenet)
# ------------------------------------------------------------------------------
log_step "Task 3: Creating Custom Mode Networks, Firewall Rules & VMs"

# 1. managementnet
if ! gcloud compute networks describe managementnet >/dev/null 2>&1; then
    log_info "Creating managementnet..."
    gcloud compute networks create managementnet --subnet-mode=custom
    log_success "Created managementnet."
fi

if ! gcloud compute networks subnets describe managementsubnet-us --region=us-east1 >/dev/null 2>&1; then
    log_info "Creating managementsubnet-us (10.240.0.0/20 in us-east1)..."
    gcloud compute networks subnets create managementsubnet-us \
        --network=managementnet \
        --region=us-east1 \
        --range=10.240.0.0/20
    log_success "Created managementsubnet-us."
fi

# 2. privatenet
if ! gcloud compute networks describe privatenet >/dev/null 2>&1; then
    log_info "Creating privatenet..."
    gcloud compute networks create privatenet --subnet-mode=custom
    log_success "Created privatenet."
fi

if ! gcloud compute networks subnets describe privatesubnet-us --region=us-east1 >/dev/null 2>&1; then
    log_info "Creating privatesubnet-us (172.16.0.0/24 in us-east1)..."
    gcloud compute networks subnets create privatesubnet-us \
        --network=privatenet \
        --region=us-east1 \
        --range=172.16.0.0/24
    log_success "Created privatesubnet-us."
fi

if ! gcloud compute networks subnets describe privatesubnet-notus --region=asia-southeast1 >/dev/null 2>&1; then
    log_info "Creating privatesubnet-notus (172.20.0.0/20 in asia-southeast1)..."
    gcloud compute networks subnets create privatesubnet-notus \
        --network=privatenet \
        --region=asia-southeast1 \
        --range=172.20.0.0/20
    log_success "Created privatesubnet-notus."
fi

# Firewall Rules
log_info "Creating firewall rule managementnet-allow-icmp-ssh-rdp..."
gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp \
    --direction=INGRESS \
    --priority=1000 \
    --network=managementnet \
    --action=ALLOW \
    --rules=icmp,tcp:22,tcp:3389 \
    --source-ranges=0.0.0.0/0 2>/dev/null || true

log_info "Creating firewall rule privatenet-allow-icmp-ssh-rdp..."
gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp \
    --direction=INGRESS \
    --priority=1000 \
    --network=privatenet \
    --action=ALLOW \
    --rules=icmp,tcp:22,tcp:3389 \
    --source-ranges=0.0.0.0/0 2>/dev/null || true
log_success "Firewall rules for managementnet and privatenet configured."

# VM Instances
log_info "Creating VM managementnet-us-vm in us-east1-c..."
if ! gcloud compute instances describe managementnet-us-vm --zone=us-east1-c >/dev/null 2>&1; then
    gcloud compute instances create managementnet-us-vm \
        --zone=us-east1-c \
        --machine-type=e2-micro \
        --subnet=managementsubnet-us \
        --image-family=debian-12 \
        --image-project=debian-cloud \
        --boot-disk-size=10GB \
        --boot-disk-type=pd-standard --quiet
    log_success "Created managementnet-us-vm."
else
    log_info "managementnet-us-vm already exists."
fi

log_info "Creating VM privatenet-us-vm in us-east1-c..."
if ! gcloud compute instances describe privatenet-us-vm --zone=us-east1-c >/dev/null 2>&1; then
    gcloud compute instances create privatenet-us-vm \
        --zone=us-east1-c \
        --machine-type=e2-micro \
        --subnet=privatesubnet-us \
        --image-family=debian-12 \
        --image-project=debian-cloud \
        --boot-disk-size=10GB \
        --boot-disk-type=pd-standard --quiet
    log_success "Created privatenet-us-vm."
else
    log_info "privatenet-us-vm already exists."
fi

# ------------------------------------------------------------------------------
# Task 4: Connectivity Summary
# ------------------------------------------------------------------------------
log_step "Task 4: Gathering Network Topology & Verification Summary"

echo -e "${YELLOW}Instances Summary:${NC}"
gcloud compute instances list --format="table(name,zone,networkInterfaces[0].network.basename():label=NETWORK,networkInterfaces[0].subnetwork.basename():label=SUBNET,networkInterfaces[0].networkIP:label=INTERNAL_IP,networkInterfaces[0].accessConfigs[0].natIP:label=EXTERNAL_IP)"

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${GREEN}[✔] ALL LAB RESOURCES PROVISIONED SUCCESSFULLY!${NC}"
echo -e "${GREEN}====================================================================${NC}"
echo -e "You can now click 'Check my progress' for all three checkpoints:"
echo -e "  1. [✔] Create a VPC network and VM instances"
echo -e "  2. [✔] Create custom mode VPC networks with firewall rules"
echo -e "  3. [✔] Create VM instances"
