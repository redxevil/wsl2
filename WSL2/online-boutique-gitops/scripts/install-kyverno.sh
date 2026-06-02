#!/usr/bin/env bash
set -euo pipefail

KYVERNO_NAMESPACE="kyverno"
KYVERNO_VERSION="v1.16.2"
KYVERNO_INSTALL_URL="https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
POLICY_DIR="${REPO_ROOT}/k8s/security/kyverno"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command kubectl

echo "Creating Kyverno namespace if needed..."
kubectl get namespace "${KYVERNO_NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${KYVERNO_NAMESPACE}"

echo "Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "${KYVERNO_INSTALL_URL}" 2>/dev/null || kubectl apply -f "${KYVERNO_INSTALL_URL}"

echo "Waiting for Kyverno controllers to become ready..."
kubectl rollout status deployment/kyverno-admission-controller -n "${KYVERNO_NAMESPACE}" --timeout=300s
kubectl rollout status deployment/kyverno-background-controller -n "${KYVERNO_NAMESPACE}" --timeout=300s
kubectl rollout status deployment/kyverno-cleanup-controller -n "${KYVERNO_NAMESPACE}" --timeout=300s
kubectl rollout status deployment/kyverno-reports-controller -n "${KYVERNO_NAMESPACE}" --timeout=300s

echo "Applying local Kyverno policies..."
kubectl apply -f "${POLICY_DIR}"

echo "Kyverno installation complete."
echo "Installed policies from: ${POLICY_DIR}"
