#!/usr/bin/env bash
# ==============================================================================
# CBL138 - Accessing the Google Cloud Console and Cloud Shell
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

export REGION="us-east1"
export ZONE="us-east1-c"
export PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}[✘] PROJECT_ID is empty. Run 'gcloud config set project <your-project-id>' first.${NC}"
    exit 1
fi

export BUCKET1="${PROJECT_ID}-bucket1"
export BUCKET2="${PROJECT_ID}-bucket2"

log_info "Project ID : $PROJECT_ID"
log_info "Region     : $REGION"
log_info "Zone       : $ZONE"
log_info "Bucket 1   : gs://$BUCKET1"
log_info "Bucket 2   : gs://$BUCKET2"

# ------------------------------------------------------------------------------
# Task 1: Create VM Instance (first-vm) & IAM Service Account
# ------------------------------------------------------------------------------
log_step "Task 1: Creating VM (first-vm) with HTTP Firewall & IAM Service Account"

# 1. Allow HTTP firewall rule
log_info "Ensuring HTTP firewall rule exists on default network..."
if ! gcloud compute firewall-rules describe default-allow-http >/dev/null 2>&1; then
    gcloud compute firewall-rules create default-allow-http \
        --direction=INGRESS \
        --priority=1000 \
        --network=default \
        --action=ALLOW \
        --rules=tcp:80 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=http-server --quiet 2>/dev/null || true
    log_success "Created default-allow-http firewall rule."
else
    log_info "Firewall rule default-allow-http already exists."
fi

# 2. VM instance: first-vm
log_info "Checking VM instance (first-vm)..."
if ! gcloud compute instances describe first-vm --zone="$ZONE" >/dev/null 2>&1; then
    log_info "Creating first-vm in $ZONE with tag http-server..."
    gcloud compute instances create first-vm \
        --zone="$ZONE" \
        --machine-type=e2-micro \
        --tags=http-server \
        --image-family=debian-12 \
        --image-project=debian-cloud \
        --boot-disk-size=10GB --quiet
    log_success "Created VM instance first-vm."
else
    log_info "Instance first-vm already exists."
fi

# 3. IAM Service Account: test-service-account
log_info "Checking Service Account: test-service-account..."
SA_EMAIL="test-service-account@${PROJECT_ID}.iam.gserviceaccount.com"
if ! gcloud iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1; then
    log_info "Creating service account test-service-account..."
    gcloud iam service-accounts create test-service-account \
        --display-name="test-service-account" --quiet
    log_success "Created service account test-service-account."
else
    log_info "Service account test-service-account already exists."
fi

log_info "Granting roles/editor to test-service-account on project $PROJECT_ID..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/editor" --quiet
log_success "Granted roles/editor to test-service-account."

# ------------------------------------------------------------------------------
# Task 3: Create Cloud Storage Buckets, Copy File & Set Public Permissions
# ------------------------------------------------------------------------------
log_step "Task 3: Managing Cloud Storage Buckets, Objects & Public Access"

# Bucket 1
log_info "Checking Bucket 1 (gs://$BUCKET1)..."
if ! gcloud storage buckets describe "gs://${BUCKET1}" >/dev/null 2>&1; then
    log_info "Creating gs://$BUCKET1..."
    gcloud storage buckets create "gs://${BUCKET1}" \
        --location=US \
        --uniform-bucket-level-access --quiet
    log_success "Created bucket gs://$BUCKET1."
else
    log_info "Bucket gs://$BUCKET1 already exists."
fi

# Bucket 2
log_info "Checking Bucket 2 (gs://$BUCKET2)..."
if ! gcloud storage buckets describe "gs://${BUCKET2}" >/dev/null 2>&1; then
    log_info "Creating gs://$BUCKET2..."
    gcloud storage buckets create "gs://${BUCKET2}" \
        --location=US --quiet
    log_success "Created bucket gs://$BUCKET2."
else
    log_info "Bucket gs://$BUCKET2 already exists."
fi

# Copy cat image
log_info "Downloading sample cat.jpg image..."
if [ ! -f "cat.jpg" ]; then
    gcloud storage cp gs://cloud-training/ak8s/cat.jpg cat.jpg --quiet
fi

log_info "Copying cat.jpg to Bucket 1 and Bucket 2..."
gcloud storage cp cat.jpg "gs://${BUCKET1}/cat.jpg" --quiet
gcloud storage cp "gs://${BUCKET1}/cat.jpg" "gs://${BUCKET2}/cat.jpg" --quiet
log_success "Uploaded cat.jpg to both buckets."

# Configure Public Access on Bucket 1
log_info "Configuring Public Access on gs://$BUCKET1..."
gcloud storage buckets update "gs://${BUCKET1}" --no-public-access-prevention 2>/dev/null || true
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET1}" \
    --member="allUsers" \
    --role="roles/storage.objectViewer" --quiet
log_success "Public access granted to allUsers on gs://$BUCKET1."

CAT_PUBLIC_URL="https://storage.googleapis.com/${BUCKET1}/cat.jpg"
log_info "Cat Image Public URL: $CAT_PUBLIC_URL"

# ------------------------------------------------------------------------------
# Task 4: Configure Cloud Shell Editor Files & Deploy Nginx on first-vm
# ------------------------------------------------------------------------------
log_step "Task 4: Configuring HTML and Deploying Nginx on first-vm"

# Local workspace repository and test directory
log_info "Setting up local test files..."
if [ ! -d "orchestrate-with-kubernetes" ]; then
    git clone https://github.com/googlecodelabs/orchestrate-with-kubernetes.git --quiet || true
fi
mkdir -p test
if [ -f "orchestrate-with-kubernetes/cleanup.sh" ]; then
    echo "echo Finished cleanup!" >> orchestrate-with-kubernetes/cleanup.sh
fi

# Prepare custom index.html
log_info "Generating index.html with cat image URL..."
cat <<EOF > index.html
<html><head><title>Cat</title></head> <body> <h1>Cat</h1> <img src="${CAT_PUBLIC_URL}"> </body></html>
EOF
log_success "Generated index.html."

# Install Nginx and deploy index.html on first-vm
log_info "Connecting to first-vm via SSH to install Nginx and deploy index.html..."
# Wait for VM to be ready for SSH
for i in {1..12}; do
    if gcloud compute ssh first-vm --zone="$ZONE" --command="true" --quiet 2>/dev/null; then
        break
    fi
    log_info "Waiting for first-vm SSH to become accessible..."
    sleep 5
done

gcloud compute scp index.html first-vm:index.html --zone="$ZONE" --quiet 2>/dev/null || \
    gcloud compute ssh first-vm --zone="$ZONE" --quiet --command="cat > index.html" < index.html

gcloud compute ssh first-vm --zone="$ZONE" --quiet --command="
    sudo apt-get remove -y --purge man-db 2>/dev/null || true
    sudo touch /var/lib/man-db/auto-update
    sudo apt-get update -y
    sudo apt-get install -y nginx
    sudo cp index.html /var/www/html/index.html
    sudo systemctl restart nginx
"
log_success "Nginx installed and index.html deployed to /var/www/html/index.html."

# Retrieve External IP
VM_IP=$(gcloud compute instances describe first-vm --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# ------------------------------------------------------------------------------
# Completion Summary
# ------------------------------------------------------------------------------
log_step "ALL TASKS COMPLETED SUCCESSFULLY!"

echo -e "${GREEN}"
echo "  [✔] Task 1: VM first-vm (e2-micro) & Service Account test-service-account (Editor role) created"
echo "  [✔] Task 3: Buckets gs://$BUCKET1 and gs://$BUCKET2 created with public cat.jpg"
echo "  [✔] Task 4: Nginx web server running with custom cat webpage on first-vm"
echo -e "${NC}"
if [ -n "$VM_IP" ]; then
    echo -e "${CYAN}Web Server URL : http://${VM_IP}${NC}"
fi
echo -e "${CYAN}Cat Public URL : ${CAT_PUBLIC_URL}${NC}\n"

echo -e "You can now click 'Check my progress' on all three checkpoints:"
echo -e "  1. [✔] Create a VM instance with necessary firewall rule, and an IAM service account"
echo -e "  2. [✔] Create Cloud Storage Buckets"
echo -e "  3. [✔] Install the nginx web server and customize the welcome page"
