#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <template> <user-arn> <output>" >&2
  exit 1
fi

template_path="$1"
user_arn="$2"
output_path="$3"

sed "s|__DESAFIO_AQUARELA_USER_ARN__|${user_arn}|g" "${template_path}" > "${output_path}"
