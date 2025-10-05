#!/bin/bash

# Deployment script for Conservice Billing Application
# Usage: ./scripts/deploy.sh [environment] [image-tag]

set -e

# Default values
ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
CLUSTER_NAME="conservice-billing-cluster"
AWS_REGION="us-east-2"
ECR_REGISTRY="942010118414.dkr.ecr.us-east-2.amazonaws.com"

echo "🚀 Starting deployment to $ENVIRONMENT environment"
echo "📦 Using image tag: $IMAGE_TAG"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed or not in PATH"
    exit 1
fi

# Update kubeconfig
echo "🔧 Updating kubeconfig for cluster: $CLUSTER_NAME"
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Verify cluster connection
echo "✅ Verifying cluster connection..."
kubectl cluster-info

# Deploy backend
echo "📦 Deploying backend service..."
kubectl patch deployment backend -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"backend\",\"image\":\"$ECR_REGISTRY/billing-backend:$IMAGE_TAG\"}]}}}}"

# Deploy frontend
echo "📦 Deploying frontend service..."
kubectl patch deployment frontend -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"frontend\",\"image\":\"$ECR_REGISTRY/billing-frontend:$IMAGE_TAG\"}]}}}}"

# Wait for deployments
echo "⏳ Waiting for deployments to complete..."
kubectl rollout status deployment/backend --timeout=300s
kubectl rollout status deployment/frontend --timeout=300s

# Verify deployment
echo "✅ Verifying deployment..."
kubectl get pods
kubectl get services
kubectl get ingress

# Health check
echo "🏥 Running health checks..."
kubectl get pods -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -q true && echo "✅ All pods are ready" || echo "❌ Some pods are not ready"

echo "🎉 Deployment completed successfully!"
echo "📊 Deployment Summary:"
echo "   Environment: $ENVIRONMENT"
echo "   Image Tag: $IMAGE_TAG"
echo "   Cluster: $CLUSTER_NAME"
echo "   Region: $AWS_REGION"
