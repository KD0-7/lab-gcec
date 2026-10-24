#!/usr/bin/env bash
# ==============================================================================
# Quick Fix for Task 4: Expose nginx pod externally
# Run this in Cloud Shell to immediately resolve Checkpoint 2
# ==============================================================================

set -euo pipefail

echo "Finding nginx-1 pod..."
my_nginx_pod=$(kubectl get pods --no-headers | awk '{print $1}' | grep '^nginx-1-' | head -n 1)

if [ -z "$my_nginx_pod" ]; then
    echo "nginx-1 pod not found! Creating deployment nginx-1..."
    kubectl create deployment --image=nginx nginx-1
    sleep 10
    my_nginx_pod=$(kubectl get pods -l app=nginx-1 -o jsonpath='{.items[0].metadata.name}')
fi

echo "Pod found: $my_nginx_pod"

# Wait for pod to be running
echo "Waiting for pod $my_nginx_pod to be Running..."
while [ "$(kubectl get pod "$my_nginx_pod" -o jsonpath='{.status.phase}' 2>/dev/null)" != "Running" ]; do
    echo -n "."
    sleep 4
done
echo ""

# Copy test.html into pod
echo "Placing test.html into container..."
cat <<EOF > "$HOME/test.html"
<header><title>This is title</title></header> Hello world
EOF

kubectl cp "$HOME/test.html" "${my_nginx_pod}:/usr/share/nginx/html/test.html"

# Expose pod via LoadBalancer service
echo "Exposing pod $my_nginx_pod via LoadBalancer service..."
kubectl expose pod "$my_nginx_pod" --port=80 --type=LoadBalancer 2>/dev/null || true

# Also expose deployment just in case
kubectl expose deployment nginx-1 --port=80 --type=LoadBalancer --name=nginx-1 2>/dev/null || true

echo "Listing services:"
kubectl get services

echo "Done! Click 'Check my progress' on 'Deploy Pods to GKE clusters' now."
