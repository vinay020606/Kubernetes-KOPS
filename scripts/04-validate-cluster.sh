#!/bin/bash
# 04-validate-cluster.sh
# Validates the created cluster.

CLUSTER_NAME=${1:-cluster.kubernetes-aws.io}
STATE_STORE=${KOPS_STATE_STORE:-s3://kubernetes-aws-io}

echo "Validating cluster: $CLUSTER_NAME (State: $STATE_STORE)"
kops validate cluster --name "$CLUSTER_NAME" --state="$STATE_STORE"

echo "Checking nodes..."
kubectl get nodes

echo "Cluster diagnostics:"
kubectl cluster-info

echo "To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'."
