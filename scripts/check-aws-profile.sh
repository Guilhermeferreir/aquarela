#!/usr/bin/env bash
set -euo pipefail

profile="${1:-aquarela-admin}"

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI nao encontrada no PATH" >&2
  exit 1
fi

echo "Validando profile AWS: ${profile}"
aws sts get-caller-identity --profile "${profile}"
echo
echo "Configuracao carregada pela AWS CLI:"
aws configure list --profile "${profile}"
