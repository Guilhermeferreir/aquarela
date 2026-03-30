#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_PATH="${1:-gitops/argocd/root-application.yaml.tpl}"
OUTPUT_PATH="${2:-/tmp/aquarela-root-application.yaml}"

if [[ -z "${REPO_URL:-}" ]]; then
  echo "REPO_URL environment variable is required" >&2
  exit 1
fi

sed "s|__REPO_URL__|${REPO_URL}|g" "${TEMPLATE_PATH}" > "${OUTPUT_PATH}"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=10m
kubectl apply -f "${OUTPUT_PATH}"
