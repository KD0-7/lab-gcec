#!/usr/bin/env bash
# Task 3: Create bastion host with dual network interfaces and SSH access
set -euo pipefail

ZONE="${ZONE:-us-east1-c}"

echo "Creating firewall rules for SSH..."
gcloud compute firewall-rules create griffin-dev-allow-ssh \
    --network=griffin-dev-vpc \
    --allow=tcp:22 \
    --source-ranges=0.0.0.0/0 2>/dev/null || true

gcloud compute firewall-rules create griffin-prod-allow-ssh \
    --network=griffin-prod-vpc \
    --allow=tcp:22 \
    --source-ranges=0.0.0.0/0 2>/dev/null || true

echo "Creating bastion host (griffin-bastion)..."
gcloud compute instances create griffin-bastion \
    --zone="$ZONE" \
    --machine-type=e2-medium \
    --tags=ssh,bastion \
    --network-interface=subnet=griffin-dev-mgmt \
    --network-interface=subnet=griffin-prod-mgmt

echo "Task 3 completed successfully."
