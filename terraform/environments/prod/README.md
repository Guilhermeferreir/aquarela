# Producao do EKS

Este diretorio provisiona a VPC, o cluster EKS, o managed node group e o usuario IAM `desafio_aquarela`.

## Fluxo

```bash
terraform init \
  -backend-config="bucket=<TF_STATE_BUCKET>" \
  -backend-config="key=environments/prod/terraform.tfstate" \
  -backend-config="region=<AWS_REGION>" \
  -backend-config="dynamodb_table=<TF_STATE_DYNAMODB_TABLE>"

cp terraform.tfvars.example terraform.tfvars
terraform plan
terraform apply
```

## Nota sobre compatibilidade

A versao padrao do cluster e `1.34` por causa da compatibilidade com o ECK. Se a Elastic passar a suportar uma versao mais nova do Kubernetes no EKS, este valor pode ser revisado.

## Pos-apply

Depois do `terraform apply`, o workflow principal usa o output `desafio_aquarela_user_arn` para renderizar e aplicar o template de `aws-auth`.
