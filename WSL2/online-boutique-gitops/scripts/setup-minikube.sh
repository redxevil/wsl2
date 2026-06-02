#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Minikube..."
minikube start --cpus=4 --memory=8192 --driver=docker

echo "Enabling addons..."
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard

echo "Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "Ensuring application namespace exists..."
kubectl get namespace dev-environment >/dev/null 2>&1 || kubectl create namespace dev-environment

if [[ -n "${DOCKERHUB_USERNAME:-}" && -n "${DOCKERHUB_PASSWORD:-}" ]]; then
  echo "Creating Docker Hub pull secret in dev-environment..."
  "${SCRIPT_DIR}/create-dockerhub-secret.sh"
else
  echo "Skipping Docker Hub secret creation."
  echo "Set DOCKERHUB_USERNAME and DOCKERHUB_PASSWORD before running this script to create docker-registry-secret."
fi

echo "Minikube is ready."
kubectl get nodes

# to make this executable, run:  chmod +x scripts/setup-minikube.sh
