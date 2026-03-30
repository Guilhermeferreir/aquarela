# Arquitetura da entrega

## Camadas

### 1. Bootstrap de acesso

- `terraform/bootstrap/github-oidc` cria o provider OIDC do GitHub Actions e a role assumida pelos workflows.
- O trust policy restringe a role ao repositorio e branch configurados.

### 2. Infraestrutura base

- `terraform/environments/prod` cria VPC, EKS, managed node group e o usuario IAM `desafio_aquarela`.
- O cluster usa `authentication_mode = "API_AND_CONFIG_MAP"` para permitir o uso do `aws-auth`.

### 3. Bootstrap pos-cluster

- O workflow instala Argo CD no namespace `argocd`.
- O workflow renderiza e aplica o template `aws-auth` com o ARN do usuario IAM criado pelo Terraform.
- O workflow aplica a aplicacao raiz do Argo CD.

### 4. Plataforma observavel

- `monitoring-stack`: instala `kube-prometheus-stack`.
- `monitoring-config`: adiciona `ServiceMonitor` e `PrometheusRule`.
- `eck-operator`: instala o operador ECK.
- `elastic-stack`: cria Elasticsearch, Kibana, APM Server e Fluent Bit.

### 5. Aplicacoes

- `sock-shop-core`: banco e microsservicos internos do Sock Shop.
- `sock-shop-frontend`: frontend separado e exposto como `LoadBalancer`.
- `apm-demo`: aplicacao Node.js simples, com rotas instrumentadas pelo Elastic APM.
