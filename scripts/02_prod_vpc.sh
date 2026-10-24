#!/usr/bin/env bash
# Task 2: Create production VPC manually
set -euo pipefail

REGION="${REGION:-us-east1}"

echo "Creating griffin-prod-vpc..."
gcloud compute networks create griffin-prod-vpc --subnet-mode=custom

echo "Creating subnet griffin-prod-wp..."
gcloud compute networks subnets create griffin-prod-wp \
    --network=griffin-prod-vpc \
    --region="$REGION" \
    --range=192.168.48.0/20

echo "Creating subnet griffin-prod-mgmt..."
gcloud compute networks subnets create griffin-prod-mgmt \
    --network=griffin-prod-vpc \
    --region="$REGION" \
    --range=192.168.64.0/20

echo "Task 2 completed successfully."
