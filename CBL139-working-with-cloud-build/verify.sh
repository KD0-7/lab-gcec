#!/usr/bin/env bash
# ==============================================================================
# CBL139 - Verification Script
# Validates Artifact Registry Images & Cloud Build History
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

REGION="us-east4"
REPO_NAME="quickstart-docker-repo"
IMAGE_NAME="quickstart-image"

echo -e "${BLUE}====================================================================${NC}"
echo -e "${CYAN}CBL139: Verifying Cloud Build & Artifact Registry Resources${NC}"
echo -e "${BLUE}====================================================================${NC}"

# Check Artifact Registry Repository
echo -e "\n${YELLOW}--- 1. Checking Artifact Registry Repository ---${NC}"
if gcloud artifacts repositories describe "$REPO_NAME" --location="$REGION" >/dev/null 2>&1; then
    echo -e "${GREEN}[✔] Repository '$REPO_NAME' exists in location '$REGION'.${NC}"
else
    echo -e "${RED}[✘] Repository '$REPO_NAME' not found!${NC}"
fi

# Check Docker Images
echo -e "\n${YELLOW}--- 2. Checking Docker Images in Artifact Registry ---${NC}"
gcloud artifacts docker images list "${REGION}-docker.pkg.dev/$(gcloud config get-value project)/${REPO_NAME}" || true

# Check Cloud Build History
echo -e "\n${YELLOW}--- 3. Recent Cloud Build Executions ---${NC}"
gcloud builds list --limit=5 --format="table(id,status,createTime,duration)"

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${GREEN}[✔] Verification complete.${NC}"
echo -e "${GREEN}====================================================================${NC}"
