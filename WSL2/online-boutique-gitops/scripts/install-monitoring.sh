#!/bin/bash
set -e

echo "Adding Helm repos..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "Installing Prometheus + Grafana..."
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin123

echo "Waiting for pods to be ready..."
kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=monitoring \
  --timeout=120s

echo "Done. Access Grafana:"
echo "kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring"