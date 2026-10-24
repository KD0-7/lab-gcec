#!/usr/bin/env bash
# Task 5: Create Kubernetes cluster
set -euo pipefail

ZONE="${ZONE:-us-east1-c}"

echo "Creating 2-node GKE cluster (griffin-dev)..."
gcloud container clusters create griffin-dev \
    --zone="$ZONE" \
    --num-nodes=2 \
    --machine-type=e2-standard-4 \
    --network=griffin-dev-vpc \
    --subnetwork=griffin-dev-wp --quiet

echo "Getting cluster credentials..."
gcloud container clusters get-credentials griffin-dev --zone="$ZONE"

echo "Task 5 completed successfully."
