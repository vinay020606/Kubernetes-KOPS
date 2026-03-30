# Manage Kubernetes Clusters on AWS Using Kops

This repository provides a step-by-step guide and helper scripts to create, manage, and delete a Kubernetes cluster on AWS using `kops` (Kubernetes Operations). This is based on the blog post ["Manage Kubernetes Clusters on AWS Using Kops"](https://aws.amazon.com/blogs/compute/manage-kubernetes-clusters-on-aws-using-kops/).

## Table of Contents
- [Prerequisites](#prerequisites)
- [1. Download Kops and Kubectl](#1-download-kops-and-kubectl)
- [2. IAM User Permission](#2-iam-user-permission)
- [3. Create an Amazon S3 Bucket for the State Store](#3-create-an-amazon-s3-bucket-for-the-state-store)
- [4. DNS Configuration](#4-dns-configuration)
- [5. Create the Kubernetes Cluster](#5-create-the-kubernetes-cluster)
- [6. Upgrade the Kubernetes Cluster](#6-upgrade-the-kubernetes-cluster)
- [7. Scaling Techniques](#7-scaling-techniques)
- [8. Delete the Kubernetes Cluster](#8-delete-the-kubernetes-cluster)

---

## Prerequisites
Before you begin, ensure you have an AWS account and have the AWS CLI installed and configured. 

## 1. Download Kops and Kubectl

You need to download the `kops` CLI, which will take care of provisioning the cluster. 

**On macOS (using brew):**
```sh
brew update && brew install kops
kops version
```

**Download kubectl:**
```sh
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```
Make sure to include the directory where `kubectl` is downloaded in your `PATH`.

## 2. IAM User Permission

The IAM user creating the Kubernetes cluster must have the following permissions:
- `AmazonEC2FullAccess`
- `AmazonRoute53FullAccess`
- `AmazonS3FullAccess`
- `IAMFullAccess`
- `AmazonVPCFullAccess`

## 3. Create an Amazon S3 Bucket for the State Store

`kops` needs a "state store" (Amazon S3 bucket) to store configuration information of the cluster.

> **Note:** Bucket names must be globally unique. This guide uses `kubernetes-aws-io`. Ensure you use a different name in your commands.

```sh
# Create an S3 bucket
aws s3api create-bucket --bucket kubernetes-aws-io

# Enable versioning (Recommended)
aws s3api put-bucket-versioning --bucket kubernetes-aws-io --versioning-configuration Status=Enabled

# Set the state store environment variable
export KOPS_STATE_STORE=s3://kubernetes-aws-io
```
You can find an automated script for this in `scripts/01-setup-s3-bucket.sh`.

## 4. DNS Configuration

A top-level domain or a subdomain is required to create the cluster. This post uses a `kubernetes-aws.io` domain registered at a third-party registrar.

Generate a Route 53 hosted zone:
```sh
ID=$(uuidgen) && \
aws route53 create-hosted-zone \
--name cluster.kubernetes-aws.io \
--caller-reference $ID \
| jq .DelegationSet.NameServers
```
Create the returned NS records for the domain with your registrar. 
You can find an automated script for this in `scripts/02-dns-configuration.sh`.

## 5. Create the Kubernetes Cluster

Start the Kubernetes cluster using the following command. This starts a single master and two worker node Kubernetes cluster.

```sh
kops create cluster \
--name cluster.kubernetes-aws.io \
--zones us-west-2a \
--state s3://kubernetes-aws-io \
--yes
```

If you want a highly available cluster with three master nodes and five worker nodes across multiple Availability Zones:
```sh
kops create cluster \
--name cluster2.kubernetes-aws.io \
--zones us-west-2a,us-west-2b,us-west-2c \
--node-count 5 \
--state s3://kubernetes-aws-io \
--yes
```

### Validate the cluster

Wait a few minutes for the cluster to be created, then validate it:
```sh
kops validate cluster --state=s3://kubernetes-aws-io
kubectl get nodes
```
You can find automated scripts for cluster creation and validation in `scripts/03-create-cluster.sh` and `scripts/04-validate-cluster.sh`.

## 6. Upgrade the Kubernetes Cluster

Kops supports rolling cluster upgrades. 

**Step 1:** Check and apply the latest recommended Kubernetes update.
```sh
kops upgrade cluster \
--name cluster2.kubernetes-aws.io \
--state s3://kubernetes-aws-io \
--yes
```

**Step 2:** Update the state store to match the cluster state.
```sh
kops update cluster \
--name cluster2.kubernetes-aws.io \
--state s3://kubernetes-aws-io \
--yes
```

**Step 3:** Perform a rolling update for all cluster nodes.
```sh
kops rolling-update cluster \
--name cluster2.kubernetes-aws.io \
--state s3://kubernetes-aws-io \
--yes
```
You can find an automated script for this in `scripts/05-upgrade-cluster.sh`.

## 7. Scaling Techniques

Kubernetes offers powerful autoscaling capabilities to handle fluctuating workloads efficiently. The two main approaches for scaling your applications are Horizontal Pod Autoscaler (HPA) and Vertical Pod Autoscaler (VPA).

### Horizontal Pod Autoscaler (HPA)

HPA automatically updates a workload resource (such as a Deployment or StatefulSet), scaling the number of pods to match demand. You can create an autoscaler that watches CPU usage and scales automatically:

```sh
kubectl autoscale deployment <deployment-name> \
  --min=2 \
  --max=10 \
  --cpu-percent=50
```

This means:
- `min=2` — always keep at least 2 pods running
- `max=10` — never exceed 10 pods
- `cpu-percent=50` — scale up when the average CPU usage across pods crosses 50%

*Note: For HPA to work based on resource utilization, the [Metrics Server](https://github.com/kubernetes-sigs/metrics-server) must be installed in your cluster.*

### Vertical Pod Autoscaler (VPA)

While HPA scales the *number* of pods (scale-out), VPA scales the *size* of the pods (scale-up). It automatically adjusts the CPU and Memory requests/limits for your pods. This is highly useful for stateful applications or workloads that cannot be easily scaled horizontally. 

To use VPA, you configure a `VerticalPodAutoscaler` object:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind:       Deployment
    name:       <deployment-name>
  updatePolicy:
    updateMode: "Auto"
```
The VPA will automatically restart your pods with the newly calculated CPU and memory reservations based on historic and current usage.
You can find examples in `scripts/07-scaling-techniques.sh`.

## 8. Delete the Kubernetes Cluster

Ensure that all resources created by the cluster are appropriately cleaned up.

```sh
kops delete cluster --state=s3://kubernetes-aws-io --yes
```

If multiple clusters have been created, specify the cluster name:
```sh
kops delete cluster cluster2.kubernetes-aws.io --state=s3://kubernetes-aws-io --yes
```
You can find an automated script for this in `scripts/06-delete-cluster.sh`.
