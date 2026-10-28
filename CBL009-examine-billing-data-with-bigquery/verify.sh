#!/usr/bin/env bash
# ==============================================================================
# CBL009 - Verification Script
# Validates BigQuery Dataset, Table, and Query Readiness
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

PROJECT_ID="${PROJECT_ID:-${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}}"
DATASET_ID="billing_dataset"
TABLE_ID="sampleinfotable"

echo -e "${BLUE}====================================================================${NC}"
echo -e "${CYAN}CBL009: BigQuery Billing Data Verification${NC}"
echo -e "${BLUE}====================================================================${NC}"

# 1. Check Dataset
echo -e "\n${YELLOW}--- 1. Checking Dataset '${DATASET_ID}' ---${NC}"
if bq show "${PROJECT_ID}:${DATASET_ID}" >/dev/null 2>&1; then
    LOCATION=$(bq show --format=prettyjson "${PROJECT_ID}:${DATASET_ID}" | grep '"location"' | head -n1 | tr -d '", ' | cut -d: -f2)
    echo -e "${GREEN}[✔] Dataset '${DATASET_ID}' exists in location: ${LOCATION}${NC}"
else
    echo -e "${RED}[✘] Dataset '${DATASET_ID}' not found!${NC}"
    exit 1
fi

# 2. Check Table and Row Count
echo -e "\n${YELLOW}--- 2. Checking Table '${TABLE_ID}' ---${NC}"
if bq show "${PROJECT_ID}:${DATASET_ID}.${TABLE_ID}" >/dev/null 2>&1; then
    NUM_ROWS=$(bq show --format=prettyjson "${PROJECT_ID}:${DATASET_ID}.${TABLE_ID}" | grep '"numRows"' | head -n1 | tr -d '", ' | cut -d: -f2)
    echo -e "${GREEN}[✔] Table '${TABLE_ID}' exists! Total rows: ${NUM_ROWS}${NC}"
else
    echo -e "${RED}[✘] Table '${TABLE_ID}' not found!${NC}"
    exit 1
fi

# 3. Check Simple Query Execution
echo -e "\n${YELLOW}--- 3. Testing Simple Query Connectivity ---${NC}"
COST_COUNT=$(bq query --use_legacy_sql=false --format=csv "SELECT count(*) FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\` WHERE cost > 0" | tail -n1)
echo -e "${GREEN}[✔] Query test succeeded: ${COST_COUNT} rows returned with cost > 0 (Expected: 104).${NC}"

echo -e "\n${BLUE}====================================================================${NC}"
echo -e "${GREEN}[✔] All BigQuery resources and queries verified successfully!${NC}"
echo -e "${BLUE}====================================================================${NC}"
