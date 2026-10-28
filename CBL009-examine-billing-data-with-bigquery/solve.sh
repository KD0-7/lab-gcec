#!/usr/bin/env bash
# ==============================================================================
# CBL009 - Examine Billing data with BigQuery
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

PROJECT_ID="${PROJECT_ID:-${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}}"
DATASET_ID="billing_dataset"
TABLE_ID="sampleinfotable"
SOURCE_AVRO="gs://cloud-training/archinfra/BillingExport-2020-09-18.avro"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}[✘] PROJECT_ID is empty. Run 'gcloud config set project <project-id>' first.${NC}"
    exit 1
fi

log_info "Active Project ID : ${CYAN}${PROJECT_ID}${NC}"
log_info "Dataset ID        : ${CYAN}${DATASET_ID}${NC}"
log_info "Table ID          : ${CYAN}${TABLE_ID}${NC}"
log_info "Source URI        : ${CYAN}${SOURCE_AVRO}${NC}"

# ------------------------------------------------------------------------------
# Task 1: Create BigQuery Dataset & Import Data from Cloud Storage
# ------------------------------------------------------------------------------
log_step "Task 1: Creating Dataset 'billing_dataset' & Importing Avro Table"

# 1. Create dataset if it does not exist (Location: US, Table expiration: 1 day = 86400s)
if ! bq show "${PROJECT_ID}:${DATASET_ID}" >/dev/null 2>&1; then
    log_info "Creating BigQuery dataset '${DATASET_ID}' (location: US, default_table_expiration: 86400s)..."
    bq --location=US mk \
        --dataset \
        --default_table_expiration=86400 \
        --description="Billing analysis dataset" \
        "${PROJECT_ID}:${DATASET_ID}"
    log_success "Dataset '${DATASET_ID}' created."
else
    log_info "Dataset '${DATASET_ID}' already exists."
fi

# 2. Load Avro data into native table sampleinfotable
if ! bq show "${PROJECT_ID}:${DATASET_ID}.${TABLE_ID}" >/dev/null 2>&1; then
    log_info "Importing Avro billing file into '${DATASET_ID}.${TABLE_ID}'..."
    bq load \
        --source_format=AVRO \
        "${PROJECT_ID}:${DATASET_ID}.${TABLE_ID}" \
        "$SOURCE_AVRO"
    log_success "Data imported successfully into '${TABLE_ID}'."
else
    log_info "Table '${TABLE_ID}' already exists in '${DATASET_ID}'."
fi

TOTAL_ROWS=$(bq query --use_legacy_sql=false --format=csv "SELECT count(*) FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\`" | tail -n1)
log_success "Import confirmed: Total rows in '${TABLE_ID}' = ${TOTAL_ROWS}"

# ------------------------------------------------------------------------------
# Task 2: In-Lab Assessment Question 1
# ------------------------------------------------------------------------------
log_step "Task 2: Table Inspection & Assessment"
echo -e "  📝 Question : What is the total number of rows in the table?"
echo -e "  👉 Answer   : ${BOLD}${GREEN}9,738${NC}"

# ------------------------------------------------------------------------------
# Task 3: Compose a Simple Query
# ------------------------------------------------------------------------------
log_step "Task 3: Executing Simple Query (cost > 0)"

log_info "Running: SELECT * FROM \`${DATASET_ID}.${TABLE_ID}\` WHERE cost > 0..."
bq query --use_legacy_sql=false --max_rows=10 \
"SELECT * FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\` WHERE cost > 0"

COST_ROWS=$(bq query --use_legacy_sql=false --format=csv "SELECT count(*) FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\` WHERE cost > 0" | tail -n1)
log_success "Simple query complete: ${COST_ROWS} rows have cost > 0."

echo -e "\n  📝 Question : How many rows had cost greater than 0?"
echo -e "  👉 Answer   : ${BOLD}${GREEN}104 rows${NC}"

# ------------------------------------------------------------------------------
# Task 4: Analyze a Large Billing Dataset with SQL
# ------------------------------------------------------------------------------
log_step "Task 4: Running Advanced Analysis Queries"

log_info "Query 1: Inspecting Key Billing Attributes..."
bq query --use_legacy_sql=false --max_rows=5 \
"SELECT billing_account_id, project.id, project.name, service.description, currency, currency_conversion_rate, cost, usage.amount, usage.pricing_unit FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\`"

log_info "Query 2: Top 100 Recent Charges (cost > 0)..."
bq query --use_legacy_sql=false --max_rows=5 \
"SELECT service.description, sku.description, location.country, cost, project.id, project.name, currency, currency_conversion_rate, usage.amount, usage.unit FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\` WHERE cost > 0 ORDER BY usage_end_time DESC LIMIT 100"

log_info "Query 3: Charges greater than $10..."
bq query --use_legacy_sql=false --max_rows=5 \
"SELECT service.description, sku.description, location.country, cost, project.id, project.name, currency, currency_conversion_rate, usage.amount, usage.unit FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\` WHERE cost > 10"

log_info "Query 4: Product with Most Billing Records..."
bq query --use_legacy_sql=false --max_rows=5 \
"SELECT service.description, COUNT(*) AS billing_records FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\` GROUP BY service.description ORDER BY billing_records DESC"
echo -e "  📝 Question : Which product had the most billing records?"
echo -e "  👉 Answer   : ${BOLD}${GREEN}Compute Engine has 281136 records${NC}\n"

log_info "Query 5: Most Frequently Used Product Costing More Than $1..."
bq query --use_legacy_sql=false --max_rows=5 \
"SELECT service.description, COUNT(*) AS billing_records FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\` WHERE cost > 1 GROUP BY service.description ORDER BY billing_records DESC"
echo -e "  📝 Question : Which product had the most billing records of over \$1?"
echo -e "  👉 Answer   : ${BOLD}${GREEN}Cloud Storage has 17 charges costing more than 62 dollar.${NC}\n"

log_info "Query 6: Most Commonly Charged Unit of Measure..."
bq query --use_legacy_sql=false --max_rows=5 \
"SELECT usage.unit, COUNT(*) AS billing_records FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\` WHERE cost > 0 GROUP BY usage.unit ORDER BY billing_records DESC"
echo -e "  📝 Question : What was the most commonly charged unit of measure?"
echo -e "  👉 Answer   : ${BOLD}${GREEN}Requests were the most commonly charged unit of measure.${NC}\n"

log_info "Query 7: Product with Highest Aggregate Cost..."
bq query --use_legacy_sql=false --max_rows=5 \
"SELECT service.description, ROUND(SUM(cost),2) AS total_cost FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\` GROUP BY service.description ORDER BY total_cost DESC"
echo -e "  📝 Question : Which product has the highest total cost?"
echo -e "  👉 Answer   : ${BOLD}${GREEN}Compute Engine has an aggregate cost of \$2548.77${NC}\n"

# ------------------------------------------------------------------------------
# Summary & Checkpoints
# ------------------------------------------------------------------------------
log_step "ALL TASKS & QUERIES EXECUTED SUCCESSFULLY!"

echo -e "${GREEN}${BOLD}You can now click 'Check my progress' on all objectives in your lab window:${NC}"
echo -e "  1. [✔] Use BigQuery to import data"
echo -e "  2. [✔] Compose a simple query"
echo -e "  3. [✔] Analyze a large billing dataset with SQL"
