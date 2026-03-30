#!/bin/bash
# 01-setup-s3-bucket.sh
# Creates an S3 bucket for the Kubernetes state store and configures versioning.

BUCKET_NAME=${1:-kubernetes-aws-io}

echo "Creating S3 bucket: $BUCKET_NAME"
aws s3api create-bucket --bucket "$BUCKET_NAME"

echo "Enabling versioning on S3 bucket: $BUCKET_NAME"
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled

echo "Done! Remember to set the environment variable:"
echo "export KOPS_STATE_STORE=s3://$BUCKET_NAME"
