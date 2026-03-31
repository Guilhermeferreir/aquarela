# Aquarela DevOps Challenge

## Resumo

Este repositorio contem a entrega completa do desafio tecnico de DevOps da Aquarela, cobrindo provisionamento do EKS com Terraform, deploy GitOps com Argo CD, observabilidade com Prometheus/Grafana/Alertmanager, stack de logs com ECK + Elasticsearch + Kibana + Fluent Bit e uma aplicacao Node.js instrumentada com Elastic APM.

O ambiente foi estruturado para funcionar com:

- AWS EKS em `us-east-1`
- GitHub Actions com OIDC e role dedicada
- Argo CD em modelo app-of-apps
- `Sock Shop` separado em `core` e `frontend`
- `apm-demo` publicado no GHCR e implantado via GitOps

## Estrutura

```text
.
+-- .github/workflows
+-- apm-demo
+-- docs
+-- gitops
+-- scripts
+-- terraform
```

## Entregas implementadas

### Infraestrutura AWS

- Cluster EKS provisionado com Terraform em [terraform/environments/prod](/home/guilhermef/clients/aquarela/terraform/environments/prod).
- Bootstrap OIDC para GitHub Actions em [terraform/bootstrap/github-oidc](/home/guilhermef/clients/aquarela/terraform/bootstrap/github-oidc).
- Managed node group para workloads do cluster.
- Usuario IAM `desafio_aquarela` reutilizado e mapeado para acesso administrativo no cluster.
- Access entries estaveis do EKS para:
  - `arn:aws:iam::135808919375:user/guilherme-ferreira`
  - `arn:aws:iam::135808919375:role/aquarela-github-actions`

### GitOps e workloads

- Argo CD bootstrapado por script e sincronizando a partir do GitHub.
- App raiz `aquarela-root` orquestrando as demais Applications.
- `sock-shop-core` e `sock-shop-frontend` separados.
- `front-end` exposto como `LoadBalancer`.
- Aplicacao `apm-demo` separada para validacao do Elastic APM.

### Observabilidade

- `kube-prometheus-stack` com Grafana, Prometheus e Alertmanager.
- ServiceMonitors e regras customizadas em [servicemonitors.yaml](/home/guilhermef/clients/aquarela/gitops/platform/monitoring-config/servicemonitors.yaml).
- Regras customizadas entregues:
  - `SockShopFrontendDown`
  - `SockShopContainerRestartsHigh`
  - `ApmDemoUnavailable`

### Logs e APM

- ECK operator em `elastic-system`.
- Elasticsearch, Kibana e APM Server em `elastic-stack`.
- Fluent Bit em DaemonSet coletando logs de `/var/log/containers`.
- Indices de logs configurados com prefixo `aquarela`.
- `apm-demo` configurado para enviar eventos ao `apm-server`.
- `apm-server` configurado para aceitar intake anonimo do servico `aquarela-apm-demo` com agente `nodejs`.

### CI/CD

- Workflow de Terraform e bootstrap do Argo CD em [.github/workflows/terraform-eks.yml](/home/guilhermef/clients/aquarela/.github/workflows/terraform-eks.yml), incluindo aplicacao opcional do secret SMTP do Alertmanager via GitHub Secrets.
- Workflow de build e push da imagem do `apm-demo` em [.github/workflows/apm-demo-image.yml](/home/guilhermef/clients/aquarela/.github/workflows/apm-demo-image.yml).
- Publicacao da imagem em lowercase no GHCR para compatibilidade com o runtime do Kubernetes.

## Configuracao atual do ambiente

### AWS e rede

Configuracao atual em [terraform.tfvars](/home/guilhermef/clients/aquarela/terraform/environments/prod/terraform.tfvars):

- Regiao: `us-east-1`
- Reuso da VPC existente: `vpc-03e89d05d2057a190`
- Nome da VPC: `vpc-desafio-devops`
- Subnets publicas:
  - `vpc-desafio-devops-public-us-east-1a`
  - `vpc-desafio-devops-public-us-east-1b`
- Subnets privadas:
  - `vpc-desafio-devops-private-us-east-1a`
  - `vpc-desafio-devops-private-us-east-1b`
- `public_access_cidrs`: `0.0.0.0/0`

### EKS e capacidade

- Nome do cluster: `aquarela-prod-eks`
- Versao do Kubernetes: `1.34`
- Tipo de instancia do node group: `t3.medium`
- Escalabilidade atual do node group:
  - `desired_size = 4`
  - `min_size = 2`
  - `max_size = 6`

### Estado remoto do Terraform

- Bucket S3: `aquarela-tf-state-guilherme`
- Lockfile S3 backend: `use_lockfile=true`
- Tabela DynamoDB historica usada no bootstrap/manual: `aquarela-tf-locks-guilherme`

### GitHub Actions

Repository variables esperadas:

- `AWS_REGION`
- `AWS_ROLE_TO_ASSUME`
- `ARGOCD_REPO_URL`
- `TF_STATE_BUCKET`
- `TF_STATE_DYNAMODB_TABLE`
- `TF_STATE_KEY`

Secrets esperados para SMTP do Alertmanager:

- `ALERTMANAGER_SMTP_SMARTHOST`
- `ALERTMANAGER_SMTP_FROM`
- `ALERTMANAGER_SMTP_AUTH_USERNAME`
- `ALERTMANAGER_SMTP_AUTH_PASSWORD`
- `ALERTMANAGER_EMAIL_TO`

## Fluxo operacional

### 1. Bootstrap do OIDC

Primeiro aplique [terraform/bootstrap/github-oidc](/home/guilhermef/clients/aquarela/terraform/bootstrap/github-oidc) para criar a role assumida pelo GitHub Actions.

Output importante:

- `github_actions_role_arn`

### 2. Provisionamento do ambiente principal

Aplique [terraform/environments/prod](/home/guilhermef/clients/aquarela/terraform/environments/prod) com o backend remoto configurado.

Esse modulo:

- reutiliza a VPC existente
- reutiliza o usuario `desafio_aquarela`
- cria/atualiza o cluster EKS
- ajusta tags de subnets para `LoadBalancer`
- cria access entries explicitas do cluster

### 3. Bootstrap do Argo CD

O script [bootstrap-argocd.sh](/home/guilhermef/clients/aquarela/scripts/bootstrap-argocd.sh):

- instala o Argo CD
- aplica `aws-auth`
- registra a app raiz

### 4. GitOps das aplicacoes

O Argo passa a sincronizar:

- `sock-shop-core`
- `sock-shop-frontend`
- `monitoring-stack`
- `monitoring-config`
- `eck-operator`
- `elastic-stack`
- `apm-demo`

## Ajustes importantes feitos durante a implantacao

### Sock Shop

- `catalogue` corrigido para nao iniciar com `-port=80` como executavel.
- `rabbitmq-exporter` atualizado para tag valida.
- `front-end` mantido exposto como `LoadBalancer`.

### Monitoring stack

- sincronizacao do `kube-prometheus-stack` ajustada para CRDs grandes.
- Prometheus Operator precisou dos CRDs completos para criar `Prometheus` e `Alertmanager`.
- `Alertmanager` recebeu correcoes na configuracao de receivers, incluindo o receiver `null`.

### Elastic e logs

- Fluent Bit configurado em [fluent-bit.yaml](/home/guilhermef/clients/aquarela/gitops/platform/elastic-stack/fluent-bit.yaml) com:
  - `Logstash_Format On`
  - `Logstash_Prefix aquarela`
- No Kibana, o data view recomendado para logs e `aquarela-*`.

### Elastic APM

- `apm-demo` usa:
  - `ELASTIC_APM_SERVICE_NAME=aquarela-apm-demo`
  - `ELASTIC_APM_ENVIRONMENT=prod`
  - `ELASTIC_APM_SERVER_URL=http://apm-server-apm-http.elastic-stack.svc:8200`
- `apm-server` ajustado para aceitar ingestao do agente `nodejs` do servico `aquarela-apm-demo`.

## Validacao e evidencias

O checklist resumido de evidencias esta em [evidence-checklist.md](/home/guilhermef/clients/aquarela/docs/evidence-checklist.md).

### Evidencias principais esperadas

1. Terraform e EKS
- `terraform apply` concluido
- `kubectl get nodes`

2. Sock Shop
- `kubectl get pods -n sock-shop`
- `kubectl get svc front-end -n sock-shop`
- navegador abrindo o frontend publico

3. Prometheus, Grafana e Alertmanager
- `kubectl get pods -n monitoring`
- dashboard do Grafana com metricas
- alerta aparecendo no Alertmanager
- evidencia do envio de e-mail

4. Elastic logs
- Kibana `Discover` com data view `aquarela-*`
- logs de pods do namespace `sock-shop` ou `apm-demo`

5. Elastic APM
- `APM > Services` mostrando `aquarela-apm-demo`
- transacoes e, idealmente, erro de `/failure`

6. GitHub Actions
- workflow `terraform-eks` verde
- workflow `apm-demo-image` verde

## Como forcar evidencias de forma segura

### Log no Kibana

Para gerar evidencia de log de pod:

```bash
kubectl rollout restart deployment apm-demo -n apm-demo
```

Depois, no Kibana `Discover`, filtre por:

- `kubernetes.namespace_name : "apm-demo"`
- `kubernetes.container_name : "apm-demo"`

### APM

Para gerar trafego no `apm-demo`:

```bash
kubectl port-forward svc/apm-demo 3001:3000 -n apm-demo
```

Em outro terminal:

```bash
curl http://localhost:3001/
curl "http://localhost:3001/work?delay=900"
curl http://localhost:3001/failure
```

### Alertmanager

A regra mais segura para teste e `ApmDemoUnavailable`, porque nao derruba o frontend da loja:

```bash
kubectl scale deployment apm-demo -n apm-demo --replicas=0
```

Apos a evidencia:

```bash
kubectl scale deployment apm-demo -n apm-demo --replicas=1
```

## Referencias oficiais

- AWS EKS: https://docs.aws.amazon.com/eks/
- Terraform AWS EKS Module: https://github.com/terraform-aws-modules/terraform-aws-eks
- Sock Shop: https://github.com/microservices-demo/microservices-demo
- kube-prometheus-stack: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- Elastic Cloud on Kubernetes: https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/install
- Fluent Bit on Kubernetes: https://docs.fluentbit.io/manual/installation/downloads/kubernetes
- Elastic APM Node.js agent: https://www.elastic.co/guide/en/apm/agent/nodejs/current/index.html
- Elastic APM anonymous auth: https://www.elastic.co/guide/en/observability/8.19/apm-configuration-anonymous.html
- Argo CD: https://argo-cd.readthedocs.io/

