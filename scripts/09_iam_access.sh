#!/usr/bin/env bash
# Task 9: Provide access for an additional engineer
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
USER2="${1:-${USER2:-}}"

if [ -z "$USER2" ]; then
    echo -ne "Enter Username 2 (Additional Engineer email): "
    read -r USER2
fi

if [ -n "$USER2" ]; then
    echo "Granting roles/editor to $USER2 on project $PROJECT_ID..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="user:${USER2}" \
        --role="roles/editor"
    echo "Task 9 completed successfully."
else
    echo "Error: Username 2 is required."
    exit 1
fi
