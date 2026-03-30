# Aquarela DevOps Challenge

Entrega completa em codigo para os itens do desafio:

- Provisionamento de EKS com Terraform.
- Deploy do Sock Shop com frontend publico.
- CI/CD com GitHub Actions.
- GitOps com Argo CD, separando `frontend` do restante da aplicacao.
- Observabilidade com Prometheus Operator, Alertmanager, ECK, Kibana, Fluent Bit e Elastic APM.
- Aplicacao Node.js de exemplo instrumentada com `elastic-apm-node`.

## Decisao de compatibilidade

Em 30 de marco de 2026, a AWS ja lista versoes mais novas do EKS, mas o ECK ainda declara suporte ate Kubernetes `1.34`. Por isso a base deste repositorio fixa o cluster em `1.34`, que e a versao mais nova compativel com todos os entregaveis pedidos.

## Documentacao principal

- Visao geral da entrega: [README.md](/home/guilhermef/clients/aquarela/README.md)
- Execucao passo a passo: [README-EXECUCAO.md](/home/guilhermef/clients/aquarela/README-EXECUCAO.md)
- Arquitetura: [docs/architecture.md](/home/guilhermef/clients/aquarela/docs/architecture.md)
- Evidencias: [docs/evidence-checklist.md](/home/guilhermef/clients/aquarela/docs/evidence-checklist.md)

## Estrutura

```text
.
├── .github/workflows
├── apm-demo
├── docs
├── gitops
├── scripts
└── terraform
```

## O que foi entregue

### Infraestrutura

- VPC dedicada com subnets publicas, privadas e intra.
- EKS com managed node group.
- IAM user `desafio_aquarela`.
- Bootstrap de OIDC para GitHub Actions.
- Template de `aws-auth` para mapear o usuario IAM como `system:masters`.

### GitOps e workloads

- Argo CD em formato app-of-apps.
- `sock-shop-core` e `sock-shop-frontend` como Applications separadas.
- Frontend exposto como `LoadBalancer`.
- App Node.js separada para demonstracao do Elastic APM.

### Observabilidade

- `kube-prometheus-stack` com Grafana, Prometheus e Alertmanager.
- Regras e ServiceMonitors para Sock Shop e app Node.js.
- ECK operator.
- Elasticsearch, Kibana e APM Server gerenciados por ECK.
- Fluent Bit coletando logs dos pods e enviando ao Elasticsearch.

## Ajustes obrigatorios antes do primeiro deploy

1. Atualize `gitops/argocd/repository-url.env` com a URL real do repositorio Git.
2. Atualize `gitops/apps/apm-demo/deployment.yaml` com a imagem real publicada no GHCR.
3. Troque os placeholders SMTP em `gitops/argocd/apps/application-monitoring-stack.yaml`.

## Repository variables esperadas no GitHub

- `AWS_REGION`
- `AWS_ROLE_TO_ASSUME`
- `ARGOCD_REPO_URL`
- `TF_STATE_BUCKET`
- `TF_STATE_DYNAMODB_TABLE`
- `TF_STATE_KEY`

## Fluxo recomendado

1. Execute o bootstrap do OIDC em `terraform/bootstrap/github-oidc`.
2. Configure as variables do repositorio.
3. Ajuste os placeholders obrigatorios descritos acima.
4. Faca push na branch `main` para disparar o workflow de Terraform.
5. O workflow aplica Terraform, renderiza o `aws-auth`, instala o Argo CD e registra a aplicacao raiz.
6. O Argo CD passa a sincronizar plataforma, observabilidade e aplicacoes.

## Evidencias

O checklist com comandos e telas esperadas esta em [docs/evidence-checklist.md](docs/evidence-checklist.md).

## Referencias oficiais

- AWS EKS: https://docs.aws.amazon.com/eks/
- Terraform AWS EKS Module: https://github.com/terraform-aws-modules/terraform-aws-eks
- Sock Shop: https://github.com/microservices-demo/microservices-demo
- kube-prometheus-stack: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- Elastic Cloud on Kubernetes: https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/install
- Fluent Bit on Kubernetes: https://docs.fluentbit.io/manual/installation/downloads/kubernetes
- Elastic APM Node.js agent: https://www.elastic.co/guide/en/apm/agent/nodejs/current/index.html
- Argo CD: https://argo-cd.readthedocs.io/

