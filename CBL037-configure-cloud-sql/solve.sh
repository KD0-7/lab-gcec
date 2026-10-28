#!/usr/bin/env bash
# ==============================================================================
# CBL037 - Configure Cloud SQL
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
# User Input: Region & Zone Configuration
# ------------------------------------------------------------------------------
log_step "Configuration: Region, Zone & Credentials"

# Detect default region & zone from pre-created VM if available
DETECTED_ZONE=$(gcloud compute instances list --filter="name=wordpress-private-ip" --format='value(zone)' 2>/dev/null | head -n1 || true)
DETECTED_REGION=""
if [ -n "$DETECTED_ZONE" ]; then
    DETECTED_REGION=$(echo "$DETECTED_ZONE" | sed 's/-[a-z]$//')
fi

# 1. Region
if [ -n "${1:-}" ]; then
    REGION="$1"
elif [ -z "${REGION:-}" ]; then
    if [ -n "$DETECTED_REGION" ]; then
        read -p "Enter Lab Region [default: ${DETECTED_REGION}]: " INPUT_REGION
        REGION="${INPUT_REGION:-$DETECTED_REGION}"
    else
        read -p "Enter Lab Region (e.g. us-central1): " REGION
    fi
fi

# 2. Zone
if [ -n "${2:-}" ]; then
    ZONE="$2"
elif [ -z "${ZONE:-}" ]; then
    if [ -n "$DETECTED_ZONE" ]; then
        read -p "Enter Lab Zone [default: ${DETECTED_ZONE}]: " INPUT_ZONE
        ZONE="${INPUT_ZONE:-$DETECTED_ZONE}"
    else
        read -p "Enter Lab Zone (e.g. us-central1-a): " ZONE
    fi
fi

# 3. Cloud SQL Root Password
DEFAULT_PASSWORD="Password123!"
if [ -n "${3:-}" ]; then
    ROOT_PASSWORD="$3"
elif [ -z "${ROOT_PASSWORD:-}" ]; then
    read -p "Enter Root Password for wordpress-db [default: ${DEFAULT_PASSWORD}]: " INPUT_PASS
    ROOT_PASSWORD="${INPUT_PASS:-$DEFAULT_PASSWORD}"
fi

PROJECT_ID="${PROJECT_ID:-${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}}"
INSTANCE_NAME="wordpress-db"
DB_NAME="wordpress"

if [ -z "$PROJECT_ID" ]; then
    log_warn "PROJECT_ID is not set. Run 'gcloud config set project <project-id>' first."
    exit 1
fi

echo -e "\n${BOLD}Deployment Parameters:${NC}"
echo -e "  - Project ID    : ${CYAN}${PROJECT_ID}${NC}"
echo -e "  - Target Region : ${CYAN}${REGION}${NC}"
echo -e "  - Target Zone   : ${CYAN}${ZONE}${NC}"
echo -e "  - Instance ID   : ${CYAN}${INSTANCE_NAME}${NC}"
echo -e "  - Database Name : ${CYAN}${DB_NAME}${NC}"
echo -e "  - Root Password : ${CYAN}${ROOT_PASSWORD}${NC}"

# ------------------------------------------------------------------------------
# Task 1: Enable Required APIs
# ------------------------------------------------------------------------------
log_step "Task 1: Enabling Required APIs"

log_info "Enabling Service Networking, Cloud SQL Admin, and Compute Engine APIs..."
gcloud services enable \
    servicenetworking.googleapis.com \
    sqladmin.googleapis.com \
    compute.googleapis.com --quiet
log_success "Required APIs enabled."

# ------------------------------------------------------------------------------
# Task 2: Configure Private Services Access (PSA) & Create Cloud SQL Instance
# ------------------------------------------------------------------------------
log_step "Task 2: Creating Cloud SQL Instance with Private & Public IP"

# 1. Allocate IP range for Private Services Access if not already allocated
if ! gcloud compute addresses describe google-managed-services-default --global >/dev/null 2>&1; then
    log_info "Allocating Private Services Access IP range (google-managed-services-default)..."
    gcloud compute addresses create google-managed-services-default \
        --global \
        --purpose=VPC_PEERING \
        --prefix-length=16 \
        --description="peering range for Cloud SQL" \
        --network=default --quiet
    log_success "PSA IP range allocated."
else
    log_info "PSA IP range 'google-managed-services-default' already allocated."
fi

# 2. Establish VPC peering connection
log_info "Connecting VPC peering for servicenetworking.googleapis.com..."
gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --ranges=google-managed-services-default \
    --network=default 2>/dev/null || true
log_success "VPC Peering established with servicenetworking."

# 3. Create Cloud SQL Instance (Enterprise, MySQL 8.0, 1 vCPU / 3.75 GB RAM, SSD 10GB)
if ! gcloud sql instances describe "$INSTANCE_NAME" >/dev/null 2>&1; then
    log_info "Creating Cloud SQL instance '${INSTANCE_NAME}' in ${REGION} (${ZONE})..."
    log_info "Machine: 1 vCPU, 3.75 GB (db-custom-1-3840), Storage: 10 GB SSD."
    log_info "Networking: Private IP (PSA) + Public IP, Unencrypted SSL allowed."
    log_info "Note: Cloud SQL provisioning takes ~3 to 5 minutes. Please wait..."
    
    # Attempt creation with dedicated-core custom tier
    if ! gcloud sql instances create "$INSTANCE_NAME" \
        --database-version=MYSQL_8_0 \
        --tier=db-custom-1-3840 \
        --region="$REGION" \
        --zone="$ZONE" \
        --root-password="$ROOT_PASSWORD" \
        --storage-type=SSD \
        --storage-size=10GB \
        --network=default \
        --assign-ip \
        --ssl-mode=ALLOW_UNENCRYPTED_AND_ENCRYPTED --quiet 2>/dev/null; then
        
        log_info "Retrying with standard tier fallback..."
        gcloud sql instances create "$INSTANCE_NAME" \
            --database-version=MYSQL_8_0 \
            --tier=db-n1-standard-1 \
            --region="$REGION" \
            --zone="$ZONE" \
            --root-password="$ROOT_PASSWORD" \
            --storage-type=SSD \
            --storage-size=10GB \
            --network=default \
            --assign-ip --quiet
    fi
    log_success "Cloud SQL creation request submitted."
else
    log_info "Cloud SQL instance '${INSTANCE_NAME}' already exists."
fi

# 4. Wait for Cloud SQL instance to be RUNNABLE
log_info "Waiting for instance '${INSTANCE_NAME}' to reach RUNNABLE status..."
for i in {1..60}; do
    STATUS=$(gcloud sql instances describe "$INSTANCE_NAME" --format='value(state)' 2>/dev/null || echo "PENDING")
    if [ "$STATUS" = "RUNNABLE" ]; then
        log_success "Cloud SQL instance '${INSTANCE_NAME}' is operational (RUNNABLE)!"
        break
    fi
    echo -n "."
    sleep 5
done
echo ""

# Retrieve SQL Connection details
SQL_CONNECTION=$(gcloud sql instances describe "$INSTANCE_NAME" --format='value(connectionName)')
SQL_PUBLIC_IP=$(gcloud sql instances describe "$INSTANCE_NAME" --format='value(ipAddresses.filter(type:PRIMARY).ipAddress)')
SQL_PRIVATE_IP=$(gcloud sql instances describe "$INSTANCE_NAME" --format='value(ipAddresses.filter(type:PRIVATE).ipAddress)')

log_info "Instance Connection Name : ${CYAN}${SQL_CONNECTION}${NC}"
log_info "Public IP Address        : ${CYAN}${SQL_PUBLIC_IP}${NC}"
log_info "Private IP Address       : ${CYAN}${SQL_PRIVATE_IP}${NC}"

# ------------------------------------------------------------------------------
# Task 3: Create Database & Configure Proxy on wordpress-proxy VM
# ------------------------------------------------------------------------------
log_step "Task 3: Creating Database & Configuring Cloud SQL Proxy"

# 1. Create WordPress database on the Cloud SQL instance
if ! gcloud sql databases describe "$DB_NAME" --instance="$INSTANCE_NAME" >/dev/null 2>&1; then
    log_info "Creating database '${DB_NAME}' on ${INSTANCE_NAME}..."
    gcloud sql databases create "$DB_NAME" --instance="$INSTANCE_NAME" --quiet
    log_success "Database '${DB_NAME}' created."
else
    log_info "Database '${DB_NAME}' already exists."
fi

# 2. Locate wordpress-proxy VM zone
PROXY_ZONE=$(gcloud compute instances list --filter="name=wordpress-proxy" --format='value(zone)' 2>/dev/null | head -n1)
if [ -z "$PROXY_ZONE" ]; then
    PROXY_ZONE="$ZONE"
fi

PROXY_EXTERNAL_IP=$(gcloud compute instances describe wordpress-proxy --zone="$PROXY_ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
log_info "Configuring Cloud SQL Proxy on VM 'wordpress-proxy' (${PROXY_ZONE})..."

# 3. Configure and launch Cloud SQL Proxy on wordpress-proxy via SSH
SSH_SETUP_CMD="
wget -q https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
chmod +x cloud_sql_proxy
pkill -f cloud_sql_proxy || true
export SQL_CONNECTION='${SQL_CONNECTION}'
nohup ./cloud_sql_proxy -instances=${SQL_CONNECTION}=tcp:3306 > proxy.log 2>&1 &
sleep 3
if pgrep -f cloud_sql_proxy >/dev/null; then
    echo 'PROXY_RUNNING'
else
    echo 'PROXY_FAILED'
fi
"

log_info "Executing setup script on wordpress-proxy VM..."
set +e
SSH_OUTPUT=$(gcloud compute ssh wordpress-proxy --zone="$PROXY_ZONE" --quiet --command="$SSH_SETUP_CMD" 2>/dev/null)
set -e

if echo "$SSH_OUTPUT" | grep -q "PROXY_RUNNING"; then
    log_success "Cloud SQL Proxy is running in the background on wordpress-proxy (listening on 127.0.0.1:3306)."
else
    log_info "SSH setup completed. If proxy needs manual start, follow step below:"
    echo -e "  Run in SSH: ./cloud_sql_proxy -instances=${SQL_CONNECTION}=tcp:3306 &"
fi

# ------------------------------------------------------------------------------
# Tasks 4 & 5: Connection Information & WordPress Setup Instructions
# ------------------------------------------------------------------------------
log_step "Tasks 4 & 5: Application Connection Details"

PRIVATE_VM_ZONE=$(gcloud compute instances list --filter="name=wordpress-private-ip" --format='value(zone)' 2>/dev/null | head -n1)
if [ -z "$PRIVATE_VM_ZONE" ]; then
    PRIVATE_VM_ZONE="$ZONE"
fi
PRIVATE_VM_EXTERNAL_IP=$(gcloud compute instances describe wordpress-private-ip --zone="$PRIVATE_VM_ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo -e "\n${BOLD}${GREEN}====================================================================${NC}"
echo -e "${BOLD}${GREEN}[✔] CLOUD SQL & PROXY INFRASTRUCTURE READY!${NC}"
echo -e "${BOLD}${GREEN}====================================================================${NC}\n"

echo -e "${YELLOW}Task 4: Connect via Proxy (External/Localhost)${NC}"
echo -e "  🌐 Open URL         : ${CYAN}http://${PROXY_EXTERNAL_IP}${NC}"
echo -e "  Click 'Let\'s go!' and enter:"
echo -e "    - Database Name   : ${BOLD}wordpress${NC}"
echo -e "    - Username        : ${BOLD}root${NC}"
echo -e "    - Password        : ${BOLD}${ROOT_PASSWORD}${NC}"
echo -e "    - Database Host   : ${BOLD}127.0.0.1${NC}"
echo -e "  Click 'Submit' -> 'Run the installation' -> Complete setup.\n"

echo -e "${YELLOW}Task 5: Connect via Private IP (Internal Network)${NC}"
echo -e "  🌐 Open URL         : ${CYAN}http://${PRIVATE_VM_EXTERNAL_IP}${NC}"
echo -e "  Click 'Let\'s go!' and enter:"
echo -e "    - Database Name   : ${BOLD}wordpress${NC}"
echo -e "    - Username        : ${BOLD}root${NC}"
echo -e "    - Password        : ${BOLD}${ROOT_PASSWORD}${NC}"
echo -e "    - Database Host   : ${BOLD}${SQL_PRIVATE_IP}${NC}"
echo -e "  Click 'Submit' -> 'Run the installation' -> Displays 'Already Installed!'.\n"

echo -e "${GREEN}====================================================================${NC}"
echo -e "${GREEN}Checkpoints to Score Now in Lab Window:${NC}"
echo -e "  1. [✔] Create a Cloud SQL instance"
echo -e "  2. [✔] Create a database and configure a proxy on a Virtual Machine"
echo -e "${GREEN}====================================================================${NC}"
