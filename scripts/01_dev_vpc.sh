#!/usr/bin/env bash
# Task 1: Create development VPC manually
set -euo pipefail

REGION="${REGION:-us-east1}"

echo "Creating griffin-dev-vpc..."
gcloud compute networks create griffin-dev-vpc --subnet-mode=custom

echo "Creating subnet griffin-dev-wp..."
gcloud compute networks subnets create griffin-dev-wp \
    --network=griffin-dev-vpc \
    --region="$REGION" \
    --range=192.168.16.0/20

echo "Creating subnet griffin-dev-mgmt..."
gcloud compute networks subnets create griffin-dev-mgmt \
    --network=griffin-dev-vpc \
    --region="$REGION" \
    --range=192.168.32.0/20

echo "Task 1 completed successfully."
