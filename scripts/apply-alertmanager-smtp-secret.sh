#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-monitoring}"
SECRET_NAME="${2:-aquarela-alertmanager-smtp}"
PASSWORD_KEY="smtp_auth_password"

if [[ -z "${ALERTMANAGER_SMTP_AUTH_PASSWORD:-}" ]]; then
  echo "ALERTMANAGER_SMTP_AUTH_PASSWORD is required" >&2
  exit 1
fi

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl -n "$NAMESPACE" create secret generic "$SECRET_NAME" \
  --from-literal="$PASSWORD_KEY=$ALERTMANAGER_SMTP_AUTH_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Alertmanager SMTP secret '$SECRET_NAME' applied in namespace '$NAMESPACE'."
