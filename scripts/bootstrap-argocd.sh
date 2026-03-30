#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_PATH="${1:-gitops/argocd/root-application.yaml.tpl}"
OUTPUT_PATH="${2:-/tmp/aquarela-root-application.yaml}"
ARGOCD_INSTALL_URL="${ARGOCD_INSTALL_URL:-https://raw.githubusercontent.com/argoproj/argo-cd/v3.3.0/manifests/install.yaml}"

if [[ -z "${REPO_URL:-}" ]]; then
  echo "REPO_URL environment variable is required" >&2
  exit 1
fi

sed "s|__REPO_URL__|${REPO_URL}|g" "${TEMPLATE_PATH}" > "${OUTPUT_PATH}"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
# Argo CD CRDs can exceed the client-side apply annotation limit; server-side apply avoids that.
# Force conflicts here because an earlier client-side apply may already own a few fields.
kubectl apply --server-side --force-conflicts -n argocd -f "${ARGOCD_INSTALL_URL}"
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=10m
kubectl apply -f "${OUTPUT_PATH}"