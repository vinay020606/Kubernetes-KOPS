#!/bin/bash
# 02-dns-configuration.sh
# Generates a Route 53 hosted zone for your domain.

DOMAIN_NAME=${1:-cluster.kubernetes-aws.io}

echo "Creating Hosted Zone on Route53 for $DOMAIN_NAME..."

ID=$(uuidgen)
aws route53 create-hosted-zone \
--name "$DOMAIN_NAME" \
--caller-reference "$ID" \
| jq .DelegationSet.NameServers

echo "IMPORTANT: Register the above NS records with your registrar or parent hosted zone!"
