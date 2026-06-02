#!/usr/bin/env bash
set -euo pipefail

ARGOCD_NAMESPACE="argocd"
APP_NAMESPACE="dev-environment"
ARGOCD_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command kubectl
require_command base64

echo "Creating namespaces if needed..."
kubectl get namespace "${ARGOCD_NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${ARGOCD_NAMESPACE}"
kubectl get namespace "${APP_NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${APP_NAMESPACE}"

echo "Installing Argo CD from the official manifest..."
kubectl apply -n "${ARGOCD_NAMESPACE}" -f "${ARGOCD_INSTALL_URL}"

echo "Waiting for Argo CD components to become ready..."
kubectl rollout status deployment/argocd-server -n "${ARGOCD_NAMESPACE}" --timeout=300s
kubectl rollout status deployment/argocd-repo-server -n "${ARGOCD_NAMESPACE}" --timeout=300s
kubectl rollout status deployment/argocd-application-controller -n "${ARGOCD_NAMESPACE}" --timeout=300s 2>/dev/null || \
kubectl rollout status statefulset/argocd-application-controller -n "${ARGOCD_NAMESPACE}" --timeout=300s

echo "Applying Argo CD project and application manifests..."
kubectl apply -f "${REPO_ROOT}/argocd/project.yml"
kubectl apply -f "${REPO_ROOT}/argocd/app.yml"

echo "Argo CD installation complete."
echo
echo "Initial admin password:"
kubectl -n "${ARGOCD_NAMESPACE}" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
echo
echo "To access the UI locally, run:"
echo "kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE} 8080:443"
