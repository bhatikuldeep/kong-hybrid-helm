#!/bin/bash

# Variables
NAMESPACE="kong"
CONTROL_PLANE_HELM_RELEASE="kong-cp"
DATA_PLANE_HELM_RELEASE="kong-dp"

# Uninstall Kong Control Plane
echo "Uninstalling Kong Control Plane (CP)..."
helm uninstall $CONTROL_PLANE_HELM_RELEASE -n $NAMESPACE
if [ $? -eq 0 ]; then
  echo "Kong Control Plane uninstalled successfully."
else
  echo "Failed to uninstall Kong Control Plane."
fi

# Uninstall Kong Data Plane
echo "Uninstalling Kong Data Plane (DP)..."
helm uninstall $DATA_PLANE_HELM_RELEASE -n $NAMESPACE
if [ $? -eq 0 ]; then
  echo "Kong Data Plane uninstalled successfully."
else
  echo "Failed to uninstall Kong Data Plane."
fi

# Delete namespace
echo "Deleting namespace $NAMESPACE..."
kubectl delete namespace $NAMESPACE
if [ $? -eq 0 ]; then
  echo "Namespace $NAMESPACE deleted successfully."
else
  echo "Failed to delete namespace or it may have been already deleted."
fi

# Final check
echo "Cleanup complete! Verify by checking for remaining resources:"
kubectl get all -n $NAMESPACE

echo "Uninstallation complete!"
