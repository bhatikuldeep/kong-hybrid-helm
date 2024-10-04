#!/bin/bash

# Exit on error, undefined variables, and ensure pipelines return the last non-zero status
set -euo pipefail

# Load environment variables from .env file
if [[ -f .env ]]; then
  source .env
else
  echo "Error: .env file not found!"
  exit 1
fi

# Default to environment variables if not set in .env file
: "${IMAGE_REPOSITORY:=kong/kong-gateway}" # Default to kong/kong-gateway if not set
: "${IMAGE_TAG:=3.8.0.0}" # Default to version 3.8.0.0 if not set

# Variables
NAMESPACE=kong
CONTROL_PLANE_HELM_RELEASE=kong-cp
DATA_PLANE_HELM_RELEASE=kong-dp
HELM_REPO="https://charts.konghq.com"
KONG_LICENSE_FILE="./license.json"
CERT_KEY_PATH="./certs/tls.key"
CERT_CRT_PATH="./certs/tls.crt"
TIMEOUT=300  # 5 minutes timeout for deployments

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check required commands
for cmd in kubectl helm openssl; do
  if ! command_exists "$cmd"; then
    echo "Error: $cmd is required but not installed."
    exit 1
  fi
done

# Check if license file exists
if [[ ! -f "$KONG_LICENSE_FILE" ]]; then
  echo "Error: Kong Enterprise license file not found at $KONG_LICENSE_FILE"
  exit 1
fi

# Function to wait for deployment
wait_for_deployment() {
  local deployment=$1
  echo "Waiting for deployment $deployment to be ready..."
  if ! kubectl rollout status deployment "$deployment" -n "$NAMESPACE" --timeout="${TIMEOUT}s"; then
    echo "Error: Deployment $deployment failed to become ready within ${TIMEOUT} seconds"
    exit 1
  fi
}

# Add Helm repo and update
echo "Adding Kong Helm repo..."
helm repo add kong "$HELM_REPO" || true
helm repo update

# Create namespace
echo "Creating namespace $NAMESPACE..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Create Kong Enterprise license secret
echo "Creating Kong license secret..."
kubectl create secret generic kong-enterprise-license \
  --from-file=license="$KONG_LICENSE_FILE" \
  -n "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

# Create secret for clustering certificates
echo "Creating secret for clustering certificates..."
kubectl create secret tls kong-cluster-cert \
  --cert="$CERT_CRT_PATH" \
  --key="$CERT_KEY_PATH" \
  -n "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

# Install Kong Control Plane (CP)
echo "Installing Kong Control Plane..."
helm upgrade --install "$CONTROL_PLANE_HELM_RELEASE" kong/kong \
  --set image.repository=$IMAGE_REPOSITORY \
  --set image.tag=$IMAGE_TAG \
  -n "$NAMESPACE" \
  --values ./cp/values-cp.yaml \
  --wait \
  --timeout "${TIMEOUT}s"

# Wait for Control Plane deployment
wait_for_deployment "$CONTROL_PLANE_HELM_RELEASE-kong"

# Install Kong Data Plane (DP)
echo "Installing Kong Data Plane..."
helm upgrade --install "$DATA_PLANE_HELM_RELEASE" kong/kong \
  --set image.repository=$IMAGE_REPOSITORY \
  --set image.tag=$IMAGE_TAG \
  -n "$NAMESPACE" \
  --values ./dp/values-dp.yaml \
  --wait \
  --timeout "${TIMEOUT}s"

# Wait for Data Plane deployment
wait_for_deployment "$DATA_PLANE_HELM_RELEASE-kong"

echo "Kong Gateway installation complete!"

# Optional: Display connection information
echo "Kong Admin API can be accessed at:"
kubectl get service -n "$NAMESPACE" "$CONTROL_PLANE_HELM_RELEASE-kong-admin" \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
echo

echo "Kong Proxy can be accessed at:"
kubectl get service -n "$NAMESPACE" "$DATA_PLANE_HELM_RELEASE-kong-proxy" \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
echo