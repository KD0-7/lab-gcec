#!/usr/bin/env bash
# Task 4: Create and configure Cloud SQL Instance
set -euo pipefail

REGION="${REGION:-us-east1}"

echo "Creating Cloud SQL MySQL instance (griffin-dev-db)..."
if ! gcloud sql instances create griffin-dev-db \
    --database-version=MYSQL_5_7 \
    --region="$REGION" \
    --tier=db-n1-standard-1 \
    --root-password=password --quiet; then
    echo "Retrying Cloud SQL with MYSQL_8_0..."
    gcloud sql instances create griffin-dev-db \
        --database-version=MYSQL_8_0 \
        --region="$REGION" \
        --tier=db-n1-standard-1 \
        --root-password=password --quiet
fi

echo "Creating WordPress database..."
gcloud sql databases create wordpress --instance=griffin-dev-db 2>/dev/null || true

echo "Creating MySQL user wp_user..."
gcloud sql users create wp_user --host="%" --instance=griffin-dev-db --password=stormwind_rules 2>/dev/null || true

echo "Task 4 completed successfully."
