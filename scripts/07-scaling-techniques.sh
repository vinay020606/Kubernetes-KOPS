#!/bin/bash
# 07-scaling-techniques.sh
# Demonstrates Horizontal Pod Autoscaler (HPA) and Vertical Pod Autoscaler (VPA).

DEPLOYMENT_NAME=${1:-my-awesome-app}

echo "=== Horizontal Pod Autoscaler (HPA) ==="
echo "Creating an HPA for deployment: $DEPLOYMENT_NAME"
echo "Rules:"
echo "  - Minimum Pods: 2"
echo "  - Maximum Pods: 10"
echo "  - Target CPU utilization: 50%"

kubectl autoscale deployment "$DEPLOYMENT_NAME" \
  --min=2 \
  --max=10 \
  --cpu-percent=50

echo "HPA created successfully. To view it, run: kubectl get hpa"
echo ""

echo "=== Vertical Pod Autoscaler (VPA) ==="
echo "For VPA, you must install the VPA components to your cluster first."
echo "Once installed, you can apply a VPA object definition like this:"

cat <<EOF | kubectl apply -f -
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: ${DEPLOYMENT_NAME}-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind:       Deployment
    name:       "$DEPLOYMENT_NAME"
  updatePolicy:
    updateMode: "Auto"
EOF

echo "VPA applied. To view it, run: kubectl get vpa"
echo "Note: The VPA will automatically monitor the pod's usage and adjust requests/limits."
