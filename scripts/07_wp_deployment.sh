#!/usr/bin/env bash
# Task 7: Create a WordPress deployment and service
set -euo pipefail

WP_DIR="$HOME/wp-k8s"
cd "$WP_DIR"

echo "Fetching Cloud SQL instance connection name..."
INSTANCE_CONNECTION_NAME=$(gcloud sql instances describe griffin-dev-db --format='value(connectionName)')
echo "Connection Name: $INSTANCE_CONNECTION_NAME"

echo "Updating wp-deployment.yaml..."
sed -i "s/YOUR_SQL_INSTANCE/${INSTANCE_CONNECTION_NAME}/g" wp-deployment.yaml

echo "Applying WordPress deployment..."
kubectl apply -f wp-deployment.yaml

echo "Applying WordPress service..."
kubectl apply -f wp-service.yaml

echo "Waiting for External IP to be assigned..."
EXTERNAL_IP=""
for i in {1..60}; do
    EXTERNAL_IP=$(kubectl get svc -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    if [ -n "$EXTERNAL_IP" ]; then
        break
    fi
    echo -n "."
    sleep 5
done
echo ""

if [ -n "$EXTERNAL_IP" ]; then
    echo "WordPress URL: http://${EXTERNAL_IP}"
fi

echo "Task 7 completed successfully."
