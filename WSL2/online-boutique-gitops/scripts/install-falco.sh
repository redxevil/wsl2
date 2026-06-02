#!/usr/bin/env bash
set -euo pipefail

FALCO_NAMESPACE="falco"
HELM_RELEASE_NAME="falco"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CUSTOM_RULES_FILE="${REPO_ROOT}/k8s/security/falco/custom-rules.yaml"
VALUES_FILE="$(mktemp)"

cleanup() {
  rm -f "${VALUES_FILE}"
}
trap cleanup EXIT

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command helm
require_command kubectl

if [[ ! -f "${CUSTOM_RULES_FILE}" ]]; then
  echo "Falco rules file not found: ${CUSTOM_RULES_FILE}" >&2
  exit 1
fi

echo "Adding Falco Helm repository..."
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

echo "Preparing Falco values with local custom rules..."
{
  echo "tty: true"
  echo "falcoctl:"
  echo "  artifact:"
  echo "    install:"
  echo "      enabled: false"
  echo "    follow:"
  echo "      enabled: false"
  echo "customRules:"
  echo "  custom-rules.yaml: |"
  sed 's/^/    /' "${CUSTOM_RULES_FILE}"
} > "${VALUES_FILE}"

echo "Installing Falco in namespace ${FALCO_NAMESPACE}..."
helm upgrade -i "${HELM_RELEASE_NAME}" falcosecurity/falco \
  --namespace "${FALCO_NAMESPACE}" \
  --create-namespace \
  -f "${VALUES_FILE}"

echo "Waiting for Falco DaemonSet to become ready..."
kubectl rollout status daemonset/falco -n "${FALCO_NAMESPACE}" --timeout=300s

echo "Falco installation complete."
echo "Custom rules loaded from: ${CUSTOM_RULES_FILE}"
