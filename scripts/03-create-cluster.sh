#!/bin/bash
# 03-create-cluster.sh
# Creates the Kubernetes cluster using kops.

CLUSTER_NAME=${1:-cluster.kubernetes-aws.io}
STATE_STORE=${KOPS_STATE_STORE:-s3://kubernetes-aws-io}
ZONES=${2:-us-west-2a}

echo "Starting cluster creation process..."
echo "Cluster Name: $CLUSTER_NAME"
echo "State Store: $STATE_STORE"
echo "Zones: $ZONES"

kops create cluster \
  --name "$CLUSTER_NAME" \
  --zones "$ZONES" \
  --state "$STATE_STORE" \
  --yes

echo "Cluster is provisioning. This may take a few minutes."
