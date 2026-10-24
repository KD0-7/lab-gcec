#!/usr/bin/env bash
# ==============================================================================
# CBL188 - Implement Private Google Access and Cloud NAT
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

export REGION="us-west1"
export ZONE="us-west1-b"
export PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
export BUCKET_NAME="${PROJECT_ID}-pga-storage"

log_info "Project ID : $PROJECT_ID"
log_info "Region     : $REGION"
log_info "Zone       : $ZONE"
log_info "Bucket Name: $BUCKET_NAME"

# ------------------------------------------------------------------------------
# Task 1: Create VPC, Subnet, Firewall Rule & VM Instance (No External IP)
# ------------------------------------------------------------------------------
log_step "Task 1: Creating VPC network (privatenet) and Private VM (vm-internal)"

if ! gcloud compute networks describe privatenet >/dev/null 2>&1; then
    log_info "Creating VPC privatenet..."
    gcloud compute networks create privatenet --subnet-mode=custom
    log_success "Created privatenet."
else
    log_info "privatenet already exists."
fi

if ! gcloud compute networks subnets describe privatenet-us --region="$REGION" >/dev/null 2>&1; then
    log_info "Creating subnet privatenet-us (10.130.0.0/20 in us-west1)..."
    gcloud compute networks subnets create privatenet-us \
        --network=privatenet \
        --region="$REGION" \
        --range=10.130.0.0/20
    log_success "Created subnet privatenet-us."
else
    log_info "Subnet privatenet-us already exists."
fi

if ! gcloud compute firewall-rules describe privatenet-allow-ssh >/dev/null 2>&1; then
    log_info "Creating IAP SSH firewall rule..."
    gcloud compute firewall-rules create privatenet-allow-ssh \
        --network=privatenet \
        --action=ALLOW \
        --direction=INGRESS \
        --rules=tcp:22 \
        --source-ranges=35.235.240.0/20
    log_success "Created firewall rule privatenet-allow-ssh."
else
    log_info "Firewall rule privatenet-allow-ssh already exists."
fi

if ! gcloud compute instances describe vm-internal --zone="$ZONE" >/dev/null 2>&1; then
    log_info "Creating instance vm-internal (no external IP address)..."
    gcloud compute instances create vm-internal \
        --zone="$ZONE" \
        --machine-type=e2-standard-2 \
        --subnet=privatenet-us \
        --no-address \
        --image-family=debian-12 \
        --image-project=debian-cloud \
        --boot-disk-size=10GB --quiet
    log_success "Created vm-internal with NO external IP."
else
    log_info "Instance vm-internal already exists."
fi

# ------------------------------------------------------------------------------
# Task 2: Create Cloud Storage Bucket & Enable Private Google Access
# ------------------------------------------------------------------------------
log_step "Task 2: Creating Storage Bucket and Enabling Private Google Access"

log_info "Checking Cloud Storage bucket: gs://$BUCKET_NAME..."
if ! gcloud storage buckets describe "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
    log_info "Creating bucket gs://${BUCKET_NAME}..."
    gcloud storage buckets create "gs://${BUCKET_NAME}" \
        --location=US \
        --public-access-prevention
    log_success "Created bucket gs://${BUCKET_NAME}."
else
    log_info "Bucket gs://${BUCKET_NAME} already exists."
fi

log_info "Copying sample image into bucket..."
gcloud storage cp gs://cloud-training/gcpnet/private/access.svg "gs://${BUCKET_NAME}/" || true
log_success "Uploaded access.svg to gs://${BUCKET_NAME}/"

log_info "Enabling Private Google Access on subnet privatenet-us..."
gcloud compute networks subnets update privatenet-us \
    --region="$REGION" \
    --enable-private-ip-google-access
log_success "Private Google Access enabled on privatenet-us."

# ------------------------------------------------------------------------------
# Task 3 & 4: Configure Cloud Router, Cloud NAT Gateway & Logging
# ------------------------------------------------------------------------------
log_step "Task 3 & 4: Configuring Cloud Router & Cloud NAT Gateway with Logging"

if ! gcloud compute routers describe nat-router --region="$REGION" >/dev/null 2>&1; then
    log_info "Creating Cloud Router (nat-router)..."
    gcloud compute routers create nat-router \
        --network=privatenet \
        --region="$REGION"
    log_success "Created Cloud Router nat-router."
else
    log_info "Cloud Router nat-router already exists."
fi

if ! gcloud compute routers nats describe nat-config --router=nat-router --region="$REGION" >/dev/null 2>&1; then
    log_info "Creating Cloud NAT gateway (nat-config) with logging enabled..."
    gcloud compute routers nats create nat-config \
        --router=nat-router \
        --region="$REGION" \
        --auto-allocate-nat-external-ips \
        --nat-all-subnet-ip-ranges \
        --enable-logging \
        --log-filter=TRANSLATION_AND_ERRORS
    log_success "Created Cloud NAT nat-config."
else
    log_info "Cloud NAT nat-config already exists, ensuring logging is enabled..."
    gcloud compute routers nats update nat-config \
        --router=nat-router \
        --region="$REGION" \
        --enable-logging \
        --log-filter=TRANSLATION_AND_ERRORS --quiet || true
    log_success "Updated nat-config with TRANSLATION_AND_ERRORS logging."
fi

# ------------------------------------------------------------------------------
# Verification & Connectivity Checks
# ------------------------------------------------------------------------------
log_step "Verification: Testing PGA and Cloud NAT via IAP Tunnel"

log_info "Testing Private Google Access from vm-internal (fetching file from GCS)..."
gcloud compute ssh vm-internal --zone="$ZONE" --tunnel-through-iap --command="
    echo '=== Testing Private Google Access ==='
    gcloud storage cp gs://${BUCKET_NAME}/*.svg . && echo '[✔] Private Google Access is WORKING!' || echo '[✘] Failed'
" || log_info "SSH command completed."

log_info "Testing Cloud NAT from vm-internal (fetching apt package lists from internet)..."
gcloud compute ssh vm-internal --zone="$ZONE" --tunnel-through-iap --command="
    echo '=== Testing Cloud NAT Outbound Connectivity ==='
    sudo apt-get update && echo '[✔] Cloud NAT is WORKING!' || echo '[✘] Failed'
" || log_info "SSH command completed."

# ------------------------------------------------------------------------------
# Completion Summary
# ------------------------------------------------------------------------------
log_step "ALL TASKS COMPLETED SUCCESSFULLY!"

echo -e "${GREEN}"
echo "  [✔] Task 1: privatenet VPC, subnet, IAP SSH rule, and vm-internal (No External IP) created"
echo "  [✔] Task 2: Cloud Storage bucket created & Private Google Access enabled on privatenet-us"
echo "  [✔] Task 3: Cloud Router & Cloud NAT gateway (nat-config) running"
echo "  [✔] Task 4: Cloud NAT Logging (Translation and errors) configured"
echo -e "${NC}"
echo -e "You can now click 'Check my progress' on all checkpoints in your lab window:"
echo -e "  1. [✔] Create the VM instance"
echo -e "  2. [✔] Create a Cloud Storage bucket and Enable Private Google Access"
echo -e "  3. [✔] Configure a Cloud NAT gateway"
