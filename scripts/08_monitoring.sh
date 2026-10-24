#!/usr/bin/env bash
# Task 8: Enable monitoring (Cloud Monitoring Uptime Check)
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"

echo "Fetching WordPress Load Balancer External IP..."
EXTERNAL_IP=""
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get svc -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    if [ -n "$EXTERNAL_IP" ]; then
        break
    fi
    sleep 5
done

if [ -z "$EXTERNAL_IP" ]; then
    echo "Warning: External IP not ready yet. Please pass IP as argument: ./08_monitoring.sh <EXTERNAL_IP>"
    EXTERNAL_IP="${1:-}"
fi

if [ -n "$EXTERNAL_IP" ]; then
    echo "Creating Uptime check for http://${EXTERNAL_IP}/..."
    TOKEN=$(gcloud auth print-access-token)
    curl -s -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "displayName": "WordPress Uptime",
            "monitoredResource": {
                "type": "uptime_url",
                "labels": {
                    "project_id": "'"$PROJECT_ID"'",
                    "host": "'"$EXTERNAL_IP"'"
                }
            },
            "httpCheck": {
                "path": "/",
                "port": 80,
                "useSsl": false
            },
            "period": "60s",
            "timeout": "10s"
        }' \
        "https://monitoring.googleapis.com/v3/projects/${PROJECT_ID}/uptimeCheckConfigs"
    echo ""
    echo "Task 8 completed successfully."
else
    echo "Could not obtain External IP. Follow manual steps in README.md."
fi
