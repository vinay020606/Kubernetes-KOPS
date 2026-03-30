#!/bin/bash
# 05-upgrade-cluster.sh
# Upgrades an existing Kubernetes cluster using Kops.

CLUSTER_NAME=${1:-cluster.kubernetes-aws.io}
STATE_STORE=${KOPS_STATE_STORE:-s3://kubernetes-aws-io}

echo "1) Upgrading cluster configuration..."
kops upgrade cluster \
  --name "$CLUSTER_NAME" \
  --state "$STATE_STORE" \
  --yes

echo "2) Updating state store..."
kops update cluster \
  --name "$CLUSTER_NAME" \
  --state "$STATE_STORE" \
  --yes

echo "3) Performing rolling update..."
kops rolling-update cluster \
  --name "$CLUSTER_NAME" \
  --state "$STATE_STORE" \
  --yes

echo "Upgrade complete."
