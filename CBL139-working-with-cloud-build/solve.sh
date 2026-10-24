#!/usr/bin/env bash
# ==============================================================================
# CBL139 - Working with Cloud Build
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

export REGION="us-east4"
export REPO_NAME="quickstart-docker-repo"
export IMAGE_NAME="quickstart-image"
export PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}[✘] PROJECT_ID is empty. Run 'gcloud config set project <your-project-id>' first.${NC}"
    exit 1
fi

log_info "Project ID : $PROJECT_ID"
log_info "Region     : $REGION"
log_info "Repository : $REPO_NAME"

# ------------------------------------------------------------------------------
# Task 1: Enable Required APIs
# ------------------------------------------------------------------------------
log_step "Task 1: Enabling Cloud Build & Artifact Registry APIs"

gcloud services enable \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com --quiet
log_success "APIs enabled."

# ------------------------------------------------------------------------------
# Task 2: Build Container with Dockerfile and Submit via gcloud
# ------------------------------------------------------------------------------
log_step "Task 2: Creating Artifact Registry Repo & First Cloud Build"

# 1. Create Artifact Registry repository
if ! gcloud artifacts repositories describe "$REPO_NAME" --location="$REGION" >/dev/null 2>&1; then
    log_info "Creating Artifact Registry repository: $REPO_NAME in $REGION..."
    gcloud artifacts repositories create "$REPO_NAME" \
        --repository-format=docker \
        --location="$REGION" \
        --description="Docker repository" --quiet
    log_success "Created Artifact Registry repository $REPO_NAME."
else
    log_info "Repository $REPO_NAME already exists."
fi

# 2. Prepare quickstart.sh and Dockerfile
log_info "Preparing initial quickstart.sh..."
cat <<'EOF' > quickstart.sh
#!/bin/sh
echo "Hello, world! The time is $(date)."
EOF
chmod +x quickstart.sh

log_info "Preparing Dockerfile..."
cat <<'EOF' > Dockerfile
FROM alpine
COPY quickstart.sh /
CMD ["/quickstart.sh"]
EOF

# 3. Submit build using --tag flag
IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:tag1"
log_info "Submitting Build 1 via gcloud builds submit --tag ${IMAGE_URI}..."
gcloud builds submit --tag "$IMAGE_URI" .
log_success "Build 1 completed and pushed to Artifact Registry."

# ------------------------------------------------------------------------------
# Task 3: Build Container Using Custom Build Config (cloudbuild.yaml)
# ------------------------------------------------------------------------------
log_step "Task 3: Running Second Build via custom cloudbuild.yaml"

cat <<EOF > cloudbuild.yaml
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: [ 'build', '-t', '${REGION}-docker.pkg.dev/\$PROJECT_ID/${REPO_NAME}/${IMAGE_NAME}:tag1', '.' ]
images:
- '${REGION}-docker.pkg.dev/\$PROJECT_ID/${REPO_NAME}/${IMAGE_NAME}:tag1'
EOF

log_info "Submitting Build 2 via gcloud builds submit --config cloudbuild.yaml..."
gcloud builds submit --config cloudbuild.yaml .
log_success "Build 2 completed."

# ------------------------------------------------------------------------------
# Task 4: Automated Container Testing & Pipeline Failure (cloudbuild2.yaml)
# ------------------------------------------------------------------------------
log_step "Task 4: Modifying quickstart.sh & Simulating Test Failure (cloudbuild2.yaml)"

# 1. Update quickstart.sh with test condition
cat <<'EOF' > quickstart.sh
#!/bin/sh
if [ -z "$1" ]
then
  echo "Hello, world! The time is $(date)."
  exit 0
else
  exit 1
fi
EOF
chmod +x quickstart.sh

# 2. Create cloudbuild2.yaml
cat <<EOF > cloudbuild2.yaml
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: [ 'build', '-t', '${REGION}-docker.pkg.dev/\$PROJECT_ID/${REPO_NAME}/${IMAGE_NAME}:tag1', '.' ]
- name: '${REGION}-docker.pkg.dev/\$PROJECT_ID/${REPO_NAME}/${IMAGE_NAME}:tag1'
  args: ['fail']
images:
- '${REGION}-docker.pkg.dev/\$PROJECT_ID/${REPO_NAME}/${IMAGE_NAME}:tag1'
EOF

# 3. Run build - expecting failure status
log_info "Submitting Build 3 (Simulated Failure Test)..."
if ! gcloud builds submit --config cloudbuild2.yaml .; then
    log_success "Build failed as expected (Return code non-zero confirmed)."
else
    log_info "Build finished."
fi

# ------------------------------------------------------------------------------
# Completion Summary
# ------------------------------------------------------------------------------
log_step "ALL TASKS COMPLETED SUCCESSFULLY!"

echo -e "${GREEN}"
echo "  [✔] Task 1: Cloud Build & Artifact Registry APIs active"
echo "  [✔] Task 2: Repository 'quickstart-docker-repo' created & first build submitted"
echo "  [✔] Task 3: Custom 'cloudbuild.yaml' build submitted"
echo "  [✔] Task 4: Automated testing failure check verified via 'cloudbuild2.yaml'"
echo -e "${NC}"

echo -e "You can now click 'Check my progress' on both checkpoints in your lab window:"
echo -e "  1. [✔] Build two container images in Cloud Build"
echo -e "  2. [✔] Build and test containers with a build configuration file and Cloud Build"
