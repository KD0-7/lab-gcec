#!/usr/bin/env bash
# Task 6: Prepare the Kubernetes cluster (secrets and volume)
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
WP_DIR="$HOME/wp-k8s"

mkdir -p "$WP_DIR"
cd "$WP_DIR"

echo "Copying configuration files from storage..."
if ! gsutil cp -r gs://spls/gsp321/wp-k8s/* . 2>/dev/null; then
    gsutil cp -r gs://cloud-training/gsp321/wp-k8s/* .
fi

echo "Updating wp-env.yaml..."
sed -i 's/username_goes_here/wp_user/g' wp-env.yaml
sed -i 's/password_goes_here/stormwind_rules/g' wp-env.yaml

echo "Applying wp-env.yaml..."
kubectl apply -f wp-env.yaml

echo "Generating service account key for cloud-sql-proxy..."
rm -f key.json
gcloud iam service-accounts keys create key.json \
    --iam-account="cloud-sql-proxy@${PROJECT_ID}.iam.gserviceaccount.com"

kubectl delete secret cloudsql-instance-credentials --ignore-not-found
kubectl create secret generic cloudsql-instance-credentials --from-file=key.json

echo "Task 6 completed successfully."
