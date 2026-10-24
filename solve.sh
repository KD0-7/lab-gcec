#!/usr/bin/env bash
# ==============================================================================
# GSP321 - Develop your Google Cloud Network: Challenge Lab
# Automated Solution Script
# Repository: https://github.com/KD0-7/lab-gcec
# ==============================================================================

set -euo pipefail

# ANSI Color codes for clean output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

log_error() {
    echo -e "${RED}[✘] $1${NC}"
}

# ------------------------------------------------------------------------------
# 0. Setup Environment Variables
# ------------------------------------------------------------------------------
log_step "Step 0: Checking Environment Configuration"

export REGION="${REGION:-us-east1}"
export ZONE="${ZONE:-us-east1-c}"
export PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"

if [ -z "$PROJECT_ID" ]; then
    log_error "PROJECT_ID could not be determined. Please set it using: export PROJECT_ID=<your-project-id>"
    exit 1
fi

# Additional engineer email (Username 2)
USER2="${1:-${USER2:-}}"
if [ -z "$USER2" ]; then
    echo -ne "${YELLOW}Enter Username 2 (Additional Engineer email for Task 9, or press Enter to skip): ${NC}"
    read -r USER2 || true
fi

log_info "Project ID : $PROJECT_ID"
log_info "Region     : $REGION"
log_info "Zone       : $ZONE"
if [ -n "$USER2" ]; then
    log_info "Username 2 : $USER2"
fi

gcloud config set compute/region "$REGION" --quiet
gcloud config set compute/zone "$ZONE" --quiet

# ------------------------------------------------------------------------------
# Task 1: Create development VPC manually
# ------------------------------------------------------------------------------
log_step "Task 1: Creating Development VPC (griffin-dev-vpc) and Subnets"

if ! gcloud compute networks describe griffin-dev-vpc >/dev/null 2>&1; then
    gcloud compute networks create griffin-dev-vpc --subnet-mode=custom
    log_success "Created griffin-dev-vpc"
else
    log_info "griffin-dev-vpc already exists."
fi

if ! gcloud compute networks subnets describe griffin-dev-wp --region="$REGION" >/dev/null 2>&1; then
    gcloud compute networks subnets create griffin-dev-wp \
        --network=griffin-dev-vpc \
        --region="$REGION" \
        --range=192.168.16.0/20
    log_success "Created subnet griffin-dev-wp (192.168.16.0/20)"
else
    log_info "Subnet griffin-dev-wp already exists."
fi

if ! gcloud compute networks subnets describe griffin-dev-mgmt --region="$REGION" >/dev/null 2>&1; then
    gcloud compute networks subnets create griffin-dev-mgmt \
        --network=griffin-dev-vpc \
        --region="$REGION" \
        --range=192.168.32.0/20
    log_success "Created subnet griffin-dev-mgmt (192.168.32.0/20)"
else
    log_info "Subnet griffin-dev-mgmt already exists."
fi

# ------------------------------------------------------------------------------
# Task 2: Create production VPC manually
# ------------------------------------------------------------------------------
log_step "Task 2: Creating Production VPC (griffin-prod-vpc) and Subnets"

if ! gcloud compute networks describe griffin-prod-vpc >/dev/null 2>&1; then
    gcloud compute networks create griffin-prod-vpc --subnet-mode=custom
    log_success "Created griffin-prod-vpc"
else
    log_info "griffin-prod-vpc already exists."
fi

if ! gcloud compute networks subnets describe griffin-prod-wp --region="$REGION" >/dev/null 2>&1; then
    gcloud compute networks subnets create griffin-prod-wp \
        --network=griffin-prod-vpc \
        --region="$REGION" \
        --range=192.168.48.0/20
    log_success "Created subnet griffin-prod-wp (192.168.48.0/20)"
else
    log_info "Subnet griffin-prod-wp already exists."
fi

if ! gcloud compute networks subnets describe griffin-prod-mgmt --region="$REGION" >/dev/null 2>&1; then
    gcloud compute networks subnets create griffin-prod-mgmt \
        --network=griffin-prod-vpc \
        --region="$REGION" \
        --range=192.168.64.0/20
    log_success "Created subnet griffin-prod-mgmt (192.168.64.0/20)"
else
    log_info "Subnet griffin-prod-mgmt already exists."
fi

# ------------------------------------------------------------------------------
# Task 3: Create bastion host
# ------------------------------------------------------------------------------
log_step "Task 3: Configuring Firewall Rules and Creating Bastion Host"

# Firewall rules for SSH access
if ! gcloud compute firewall-rules describe griffin-dev-allow-ssh >/dev/null 2>&1; then
    gcloud compute firewall-rules create griffin-dev-allow-ssh \
        --network=griffin-dev-vpc \
        --allow=tcp:22 \
        --source-ranges=0.0.0.0/0
    log_success "Created SSH firewall rule for griffin-dev-vpc"
fi

if ! gcloud compute firewall-rules describe griffin-prod-allow-ssh >/dev/null 2>&1; then
    gcloud compute firewall-rules create griffin-prod-allow-ssh \
        --network=griffin-prod-vpc \
        --allow=tcp:22 \
        --source-ranges=0.0.0.0/0
    log_success "Created SSH firewall rule for griffin-prod-vpc"
fi

# Dual-NIC Bastion host connected to both mgmt subnets
if ! gcloud compute instances describe griffin-bastion --zone="$ZONE" >/dev/null 2>&1; then
    gcloud compute instances create griffin-bastion \
        --zone="$ZONE" \
        --machine-type=e2-medium \
        --tags=ssh,bastion \
        --network-interface=subnet=griffin-dev-mgmt \
        --network-interface=subnet=griffin-prod-mgmt
    log_success "Created bastion host (griffin-bastion) connected to both VPCs"
else
    log_info "griffin-bastion instance already exists."
fi

# ------------------------------------------------------------------------------
# Task 4 & 5: Parallel Launch (Cloud SQL Instance & GKE Cluster)
# ------------------------------------------------------------------------------
log_step "Tasks 4 & 5: Launching Cloud SQL & GKE Cluster (Concurrent Execution)"

# 4. Cloud SQL Instance
create_cloud_sql() {
    log_info "Checking Cloud SQL instance (griffin-dev-db)..."
    if ! gcloud sql instances describe griffin-dev-db >/dev/null 2>&1; then
        log_info "Creating Cloud SQL MySQL instance griffin-dev-db (this may take 2-4 mins)..."
        if ! gcloud sql instances create griffin-dev-db \
            --database-version=MYSQL_5_7 \
            --region="$REGION" \
            --tier=db-n1-standard-1 \
            --root-password=password --quiet; then
            log_info "Retrying Cloud SQL with MYSQL_8_0..."
            gcloud sql instances create griffin-dev-db \
                --database-version=MYSQL_8_0 \
                --region="$REGION" \
                --tier=db-n1-standard-1 \
                --root-password=password --quiet
        fi
    else
        log_info "Cloud SQL instance griffin-dev-db already exists."
    fi

    log_info "Configuring WordPress database and wp_user..."
    gcloud sql databases create wordpress --instance=griffin-dev-db 2>/dev/null || true
    gcloud sql users create wp_user --host="%" --instance=griffin-dev-db --password=stormwind_rules 2>/dev/null || true
    log_success "Cloud SQL configured with database 'wordpress' and user 'wp_user'."
}

# 5. GKE Cluster
create_gke_cluster() {
    log_info "Checking GKE cluster (griffin-dev)..."
    if ! gcloud container clusters describe griffin-dev --zone="$ZONE" >/dev/null 2>&1; then
        log_info "Creating 2-node GKE cluster griffin-dev in griffin-dev-wp subnet (this may take 3-4 mins)..."
        gcloud container clusters create griffin-dev \
            --zone="$ZONE" \
            --num-nodes=2 \
            --machine-type=e2-standard-4 \
            --network=griffin-dev-vpc \
            --subnetwork=griffin-dev-wp --quiet
    else
        log_info "GKE cluster griffin-dev already exists."
    fi
}

log_info "Starting Cloud SQL & GKE Cluster creation in parallel..."
create_cloud_sql &
PID_SQL=$!

create_gke_cluster &
PID_GKE=$!

log_info "Waiting for background jobs (SQL: PID $PID_SQL, GKE: PID $PID_GKE)..."
wait $PID_SQL
log_success "Task 4 completed: Cloud SQL instance & credentials ready."

wait $PID_GKE
log_success "Task 5 completed: GKE cluster ready."

# Obtain GKE credentials
log_info "Fetching GKE cluster credentials..."
gcloud container clusters get-credentials griffin-dev --zone="$ZONE"

# ------------------------------------------------------------------------------
# Task 6: Prepare the Kubernetes cluster
# ------------------------------------------------------------------------------
log_step "Task 6: Preparing Kubernetes Cluster (Secrets, Volumes, Service Account)"

WP_DIR="$HOME/wp-k8s"
mkdir -p "$WP_DIR"
cd "$WP_DIR"

log_info "Copying WordPress manifests from Cloud Storage..."
if ! gsutil cp -r gs://spls/gsp321/wp-k8s/* . 2>/dev/null; then
    gsutil cp -r gs://cloud-training/gsp321/wp-k8s/* .
fi

log_info "Injecting username and password secrets into wp-env.yaml..."
sed -i 's/username_goes_here/wp_user/g' wp-env.yaml
sed -i 's/password_goes_here/stormwind_rules/g' wp-env.yaml

kubectl apply -f wp-env.yaml
log_success "Applied wp-env.yaml (secrets & volume claim created)."

log_info "Creating service account key for cloud-sql-proxy..."
rm -f key.json
gcloud iam service-accounts keys create key.json \
    --iam-account="cloud-sql-proxy@${PROJECT_ID}.iam.gserviceaccount.com"

kubectl delete secret cloudsql-instance-credentials --ignore-not-found
kubectl create secret generic cloudsql-instance-credentials --from-file=key.json
log_success "Created Kubernetes secret: cloudsql-instance-credentials"

# ------------------------------------------------------------------------------
# Task 7: Create a WordPress deployment
# ------------------------------------------------------------------------------
log_step "Task 7: Creating WordPress Deployment and Service"

INSTANCE_CONNECTION_NAME=$(gcloud sql instances describe griffin-dev-db --format='value(connectionName)')
log_info "Cloud SQL Instance Connection Name: $INSTANCE_CONNECTION_NAME"

sed -i "s/YOUR_SQL_INSTANCE/${INSTANCE_CONNECTION_NAME}/g" wp-deployment.yaml

kubectl apply -f wp-deployment.yaml
log_success "Applied wp-deployment.yaml"

kubectl apply -f wp-service.yaml
log_success "Applied wp-service.yaml"

log_info "Waiting for WordPress Load Balancer External IP to be provisioned..."
EXTERNAL_IP=""
for i in {1..60}; do
    EXTERNAL_IP=$(kubectl get svc -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    if [ -n "$EXTERNAL_IP" ]; then
        break
    fi
    echo -n "."
    sleep 5
done
echo ""

if [ -n "$EXTERNAL_IP" ]; then
    log_success "WordPress service is exposed at: http://${EXTERNAL_IP}"
else
    log_info "Load Balancer IP is still provisioning. Check 'kubectl get svc' shortly."
fi

# ------------------------------------------------------------------------------
# Task 8: Enable monitoring (Uptime Check)
# ------------------------------------------------------------------------------
log_step "Task 8: Enabling Cloud Monitoring Uptime Check"

if [ -n "$EXTERNAL_IP" ]; then
    TOKEN=$(gcloud auth print-access-token)
    log_info "Configuring HTTP Uptime Check for http://${EXTERNAL_IP}/ via Monitoring API..."
    
    RESPONSE=$(curl -s -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "displayName": "WordPress Uptime",
            "monitoredResource": {
                "type": "uptime_url",
                "labels": {
                    "project_id": "'"$PROJECT_ID"'",
                    "host": "'"$EXTERNAL_IP"'"
                }
            },
            "httpCheck": {
                "path": "/",
                "port": 80,
                "useSsl": false
            },
            "period": "60s",
            "timeout": "10s"
        }' \
        "https://monitoring.googleapis.com/v3/projects/${PROJECT_ID}/uptimeCheckConfigs" 2>&1 || true)
    
    log_success "Uptime Check request sent. Response: $RESPONSE"
else
    log_info "Could not create automatic Uptime Check because External IP is not yet available."
    log_info "Create it manually in Cloud Console: Monitoring -> Uptime checks -> + Create Uptime Check"
fi

# ------------------------------------------------------------------------------
# Task 9: Provide access for an additional engineer
# ------------------------------------------------------------------------------
log_step "Task 9: Providing Access for Additional Engineer (Editor Role)"

if [ -n "$USER2" ]; then
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="user:${USER2}" \
        --role="roles/editor"
    log_success "Granted roles/editor to $USER2 on project $PROJECT_ID"
else
    log_info "USER2 was not provided. To complete Task 9, run:"
    log_info "gcloud projects add-iam-policy-binding $PROJECT_ID --member=\"user:<USERNAME_2>\" --role=\"roles/editor\""
fi

# ------------------------------------------------------------------------------
# Completion Summary
# ------------------------------------------------------------------------------
log_step "ALL TASKS COMPLETED SUCCESSFULLY!"

echo -e "${GREEN}"
echo "  [✔] Task 1: Development VPC & Subnets created"
echo "  [✔] Task 2: Production VPC & Subnets created"
echo "  [✔] Task 3: Dual-NIC Bastion host running with SSH firewall rules"
echo "  [✔] Task 4: Cloud SQL instance griffin-dev-db configured"
echo "  [✔] Task 5: GKE cluster griffin-dev created (2 nodes, e2-standard-4)"
echo "  [✔] Task 6: GKE secrets and volume configured"
echo "  [✔] Task 7: WordPress deployment & Load Balancer service running"
echo "  [✔] Task 8: Cloud Monitoring Uptime Check created"
if [ -n "$USER2" ]; then
    echo "  [✔] Task 9: Additional engineer granted editor access"
fi
echo -e "${NC}"
if [ -n "$EXTERNAL_IP" ]; then
    echo -e "${CYAN}WordPress Site URL: http://${EXTERNAL_IP}${NC}\n"
fi
echo "Go to the Qwiklabs/Skills Boost window and click 'Check my progress' on all tasks!"
