#!/bin/bash
# 06-delete-cluster.sh
# Deletes the Kubernetes cluster to clean up resources.

CLUSTER_NAME=${1:-cluster.kubernetes-aws.io}
STATE_STORE=${KOPS_STATE_STORE:-s3://kubernetes-aws-io}

echo "WARNING: Deleting cluster $CLUSTER_NAME..."

read -p "Are you sure you want to delete this cluster? This action is irreversible! [y/N]: " CONFIRM

if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
  echo "Deleting cluster..."
  kops delete cluster \
    --name "$CLUSTER_NAME" \
    --state="$STATE_STORE" \
    --yes
  echo "Cluster deleted."
else
  echo "Deletion canceled."
  exit 0
fi
