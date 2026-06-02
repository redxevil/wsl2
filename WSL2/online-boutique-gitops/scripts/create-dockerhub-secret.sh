#!/usr/bin/env bash
set -euo pipefail

SECRET_NAME="docker-registry-secret"
NAMESPACE="dev-environment"
DOCKER_SERVER="${DOCKER_SERVER:-https://index.docker.io/v1/}"
DOCKER_EMAIL="${DOCKER_EMAIL:-codex@openai.com}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command kubectl

: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME before running this script.}"
: "${DOCKERHUB_PASSWORD:?Set DOCKERHUB_PASSWORD before running this script.}"

kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

kubectl create secret docker-registry "${SECRET_NAME}" \
  --namespace "${NAMESPACE}" \
  --docker-server="${DOCKER_SERVER}" \
  --docker-username="${DOCKERHUB_USERNAME}" \
  --docker-password="${DOCKERHUB_PASSWORD}" \
  --docker-email="${DOCKER_EMAIL}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Created or updated ${SECRET_NAME} in namespace ${NAMESPACE}."
