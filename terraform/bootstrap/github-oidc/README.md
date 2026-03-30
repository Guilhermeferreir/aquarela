# Bootstrap GitHub OIDC

Este diretorio deve ser aplicado uma unica vez com credenciais administrativas da AWS.

## Objetivo

- Criar o provider OIDC do GitHub Actions.
- Criar a role assumida pelo workflow principal via `aws-actions/configure-aws-credentials`.

## Uso

```bash
terraform init \
  -backend-config="bucket=<TF_STATE_BUCKET>" \
  -backend-config="key=bootstrap/github-oidc.tfstate" \
  -backend-config="region=<AWS_REGION>" \
  -backend-config="dynamodb_table=<TF_STATE_DYNAMODB_TABLE>"

cp terraform.tfvars.example terraform.tfvars
terraform plan
terraform apply
```

## Observacao

A role usa `AdministratorAccess` para simplificar o desafio e permitir provisionamento ponta a ponta. Em um ambiente real, troque por uma policy de menor privilegio.
