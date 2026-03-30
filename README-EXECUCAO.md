# Guia de Execucao

Este documento descreve o passo a passo completo para preparar o ambiente, provisionar a infraestrutura e validar todos os entregaveis do desafio.

## 1. Visao geral

A ordem recomendada e esta:

1. Preparar ferramentas locais.
2. Criar bucket e tabela do backend remoto do Terraform.
3. Aplicar o bootstrap do OIDC do GitHub Actions.
4. Configurar variables e secrets do repositorio.
5. Ajustar os placeholders do repositorio.
6. Publicar a imagem da aplicacao `apm-demo`.
7. Fazer push na branch `main`.
8. Acompanhar o workflow de Terraform.
9. Validar Argo CD, Sock Shop, Prometheus, Alertmanager, Kibana e APM.

## 2. Ferramentas necessarias

Instale localmente:

- `aws` CLI v2
- `terraform` >= 1.8
- `kubectl`
- `git`
- acesso administrativo na conta AWS onde o desafio sera executado
- acesso de maintainer/admin no repositorio GitHub

Comandos uteis para checagem:

```bash
aws --version
terraform --version
kubectl version --client
git --version
```

## 2.1 Autenticacao na conta

Pelo seu fluxo atual, a autenticacao inicial e feita com **IAM User sign in** no console da AWS, usando:

- account alias ou account ID
- IAM username
- password

Exemplo do seu ambiente atual:

- alias da conta: `nuke-lab`
- usuario IAM: `guilherme-ferreira`

Importante: esse login no console **nao autentica automaticamente o terminal local**. Para rodar `aws`, `terraform` e `kubectl`, voce precisa de uma destas abordagens.

### Opcao A: usar AWS CloudShell depois do login no console

Essa costuma ser a opcao mais simples quando voce ja entra com IAM user no navegador.

Passos:

1. Faca login no console AWS com seu usuario IAM.
2. Abra o **AWS CloudShell**.
3. Rode no CloudShell:

```bash
aws sts get-caller-identity
aws configure list
```

Se o `sts get-caller-identity` retornar sua conta e seu ARN, voce ja esta autenticado naquele shell e pode executar dali os comandos de bootstrap do Terraform e da AWS.

### Opcao B: criar access key para o IAM user e configurar a AWS CLI local

Se voce quiser executar tudo do seu computador, o usuario IAM precisa ter uma **Access Key** para uso programatico.

#### Passo 1: criar a access key no console AWS

Com seu login atual no console:

- account alias: `nuke-lab`
- IAM username: `guilherme-ferreira`

Faca o seguinte:

1. Entre no console AWS com seu IAM user.
2. Abra o servico **IAM**.
3. Va em `Users`.
4. Clique no usuario `guilherme-ferreira`.
5. Abra a aba `Security credentials`.
6. Na secao `Access keys`, clique em `Create access key`.
7. Se a AWS pedir o caso de uso, escolha `Command Line Interface (CLI)`.
8. Confirme a criacao.
9. Copie e guarde imediatamente:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

Importante:

- a AWS mostra o `Secret Access Key` apenas uma vez;
- se perder essa chave, sera necessario criar outra;
- prefira baixar o `.csv` da credencial no momento da criacao.

#### Passo 2: configurar a AWS CLI local

No seu terminal local, rode:

```bash
aws configure --profile aquarela-admin
```

A CLI vai pedir os valores nesta ordem:

```text
AWS Access Key ID [None]: <cole a access key id>
AWS Secret Access Key [None]: <cole a secret access key>
Default region name [None]: us-east-1
Default output format [None]: json
```

#### Passo 3: ativar o profile na sessao

```bash
export AWS_PROFILE=aquarela-admin
```

Se voce estiver no PowerShell, use:

```powershell
$env:AWS_PROFILE = 'aquarela-admin'
```

#### Passo 4: validar a autenticacao

```bash
aws sts get-caller-identity
aws configure list
```

Se tudo estiver correto, o `sts get-caller-identity` vai retornar algo parecido com:

```json
{
  "UserId": "AIDA...",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/guilherme-ferreira"
}
```

#### Passo 5: confirmar onde a AWS CLI gravou as credenciais

Linux/macOS/WSL:

```bash
cat ~/.aws/credentials
cat ~/.aws/config
```

Exemplo esperado:

```ini
# ~/.aws/credentials
[aquarela-admin]
aws_access_key_id = SUA_ACCESS_KEY
aws_secret_access_key = SUA_SECRET_KEY
```

```ini
# ~/.aws/config
[profile aquarela-admin]
region = us-east-1
output = json
```

#### Passo 6: usar esse profile no restante do desafio

Com o profile ativo, os proximos comandos passam a usar automaticamente essa autenticacao:

```bash
aws sts get-caller-identity
terraform init
terraform plan
kubectl version --client
```

Se preferir nao exportar a variavel, voce tambem pode chamar explicitamente:

```bash
aws sts get-caller-identity --profile aquarela-admin
```

### Quando usar cada opcao

- Use **CloudShell** se quiser evitar configurar chaves localmente.
- Use **AWS CLI local com profile** se quiser rodar tudo da sua maquina.

### GitHub

Para acompanhar workflows e ajustar variables/secrets com mais facilidade, voce tambem pode autenticar no GitHub CLI:

```bash
gh auth login
gh auth status
```

Observacao importante:

- o bootstrap manual usa sua autenticacao AWS direta, seja por CloudShell ou AWS CLI local;
- o GitHub Actions usa a role configurada via OIDC, nao sua senha do console e nem seu profile local.
## 3. Preparacao inicial na AWS

### 3.1 Escolha a regiao

Exemplo usado nesta documentacao:

```bash
export AWS_REGION=us-east-1
```

### 3.2 Crie o backend remoto do Terraform

Crie um bucket S3 e uma tabela DynamoDB para lock do estado.

Exemplo:

```bash
aws s3 mb s3://aquarela-tf-state --region $AWS_REGION

aws dynamodb create-table \
  --region $AWS_REGION \
  --table-name aquarela-tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Guarde estes valores:

- `TF_STATE_BUCKET=aquarela-tf-state`
- `TF_STATE_DYNAMODB_TABLE=aquarela-tf-locks`
- `TF_STATE_KEY=environments/prod/terraform.tfstate`

## 4. Bootstrap do GitHub OIDC

Entre em [terraform/bootstrap/github-oidc](/home/guilhermef/clients/aquarela/terraform/bootstrap/github-oidc).

### 4.1 Copie o arquivo de exemplo

```bash
cd terraform/bootstrap/github-oidc
cp terraform.tfvars.example terraform.tfvars
```

### 4.2 Ajuste o `terraform.tfvars`

Preencha pelo menos:

```hcl
region       = "us-east-1"
github_owner = "SEU_USUARIO_OU_ORG"
github_repo  = "aquarela"
github_branch = "main"

additional_subjects = [
  "repo:SEU_USUARIO_OU_ORG/aquarela:pull_request",
]
```

### 4.3 Inicialize e aplique

```bash
terraform init \
  -backend-config="bucket=aquarela-tf-state" \
  -backend-config="key=bootstrap/github-oidc.tfstate" \
  -backend-config="region=$AWS_REGION" \
  -backend-config="dynamodb_table=aquarela-tf-locks"

terraform plan
terraform apply
```

Ao final, copie o output `github_actions_role_arn`.

## 5. Configuracao do repositorio GitHub

### 5.1 Repository Variables

Em `Settings > Secrets and variables > Actions > Variables`, configure:

- `AWS_REGION`
- `AWS_ROLE_TO_ASSUME`
- `ARGOCD_REPO_URL`
- `TF_STATE_BUCKET`
- `TF_STATE_DYNAMODB_TABLE`
- `TF_STATE_KEY`

Exemplo:

- `AWS_REGION=us-east-1`
- `AWS_ROLE_TO_ASSUME=arn:aws:iam::<ACCOUNT_ID>:role/aquarela-github-actions`
- `ARGOCD_REPO_URL=https://github.com/SEU_USUARIO_OU_ORG/aquarela.git`
- `TF_STATE_BUCKET=aquarela-tf-state`
- `TF_STATE_DYNAMODB_TABLE=aquarela-tf-locks`
- `TF_STATE_KEY=environments/prod/terraform.tfstate`

### 5.2 Repository Secrets

Em `Settings > Secrets and variables > Actions > Secrets`, configure os valores SMTP reais:

- `ALERTMANAGER_SMTP_SMARTHOST`
- `ALERTMANAGER_SMTP_FROM`
- `ALERTMANAGER_SMTP_AUTH_USERNAME`
- `ALERTMANAGER_SMTP_AUTH_PASSWORD`
- `ALERTMANAGER_EMAIL_TO`

Observacao: o arquivo atual do Argo CD ainda contem placeholders estaticos para SMTP. Antes do deploy real, troque esses placeholders em [gitops/argocd/apps/application-monitoring-stack.yaml](/home/guilhermef/clients/aquarela/gitops/argocd/apps/application-monitoring-stack.yaml).

## 6. Ajustes obrigatorios no repositorio

Antes do primeiro push de provisionamento, revise estes arquivos:

### 6.1 URL do repositorio usada pelo Argo CD

Arquivo: [gitops/argocd/repository-url.env](/home/guilhermef/clients/aquarela/gitops/argocd/repository-url.env)

Troque:

```env
REPO_URL=https://github.com/CHANGE-ME/aquarela.git
```

Pela URL real do repositorio.

### 6.2 Imagem do `apm-demo`

Arquivo: [gitops/apps/apm-demo/deployment.yaml](/home/guilhermef/clients/aquarela/gitops/apps/apm-demo/deployment.yaml)

Troque:

```yaml
image: ghcr.io/CHANGE-ME/aquarela-apm-demo:latest
```

Pelo namespace correto do GHCR.

### 6.3 `terraform.tfvars` do ambiente principal

Entre em [terraform/environments/prod](/home/guilhermef/clients/aquarela/terraform/environments/prod):

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
```

Ajuste se necessario:

- regiao
- `public_access_cidrs`
- tipo e quantidade de instancias
- tags

## 7. Publicacao da imagem da app APM

O repositorio ja tem workflow em [.github/workflows/apm-demo-image.yml](/home/guilhermef/clients/aquarela/.github/workflows/apm-demo-image.yml).

Voce pode:

1. Fazer push na `main` com mudancas em `apm-demo/`.
2. Ou disparar manualmente o workflow `apm-demo-image`.

Depois confirme no GHCR que a imagem `ghcr.io/<owner>/aquarela-apm-demo:latest` foi publicada.

## 8. Provisionamento principal

Depois de configurar tudo, faca commit e push:

```bash
git add .
git commit -m "chore: add complete devops challenge delivery"
git push origin main
```

O workflow [.github/workflows/terraform-eks.yml](/home/guilhermef/clients/aquarela/.github/workflows/terraform-eks.yml) vai executar:

1. `terraform fmt -check`
2. `terraform init`
3. `terraform validate`
4. `terraform plan`
5. `terraform apply`
6. export dos outputs
7. `aws eks update-kubeconfig`
8. render e apply do `aws-auth`
9. instalacao do Argo CD
10. registro da aplicacao raiz do Argo

## 9. Acompanhando o bootstrap

### 9.1 Verifique o cluster

Depois do workflow concluir:

```bash
aws eks update-kubeconfig --name aquarela-prod-eks --region $AWS_REGION
kubectl get nodes
```

### 9.2 Verifique o Argo CD

```bash
kubectl get pods -n argocd
kubectl port-forward svc/argocd-server 8080:443 -n argocd
```

Acesse `https://localhost:8080`.

### 9.3 Pegue a senha inicial do Argo CD

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

## 10. Validacao do Sock Shop

### 10.1 Pods e services

```bash
kubectl get pods -n sock-shop
kubectl get svc -n sock-shop
```

### 10.2 Frontend publico

O service `front-end` deve estar como `LoadBalancer`.

```bash
kubectl get svc front-end -n sock-shop
```

Quando o `EXTERNAL-IP` estiver preenchido, abra no navegador.

## 11. Validacao do Prometheus, Grafana e Alertmanager

### 11.1 Pods

```bash
kubectl get pods -n monitoring
```

### 11.2 Port-forward

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
```

Grafana: `http://localhost:3000`
Prometheus: `http://localhost:9090`

### 11.3 Teste de alerta

Force a queda do frontend:

```bash
kubectl scale deployment/front-end --replicas=0 -n sock-shop
```

Aguarde o alerta `SockShopFrontendDown` e confirme o e-mail.

Depois restaure:

```bash
kubectl scale deployment/front-end --replicas=2 -n sock-shop
```

## 12. Validacao do ECK, Kibana e logs

### 12.1 Recursos Elastic

```bash
kubectl get pods -n elastic-system
kubectl get pods -n elastic-stack
```

### 12.2 Acesso ao Kibana

```bash
kubectl port-forward svc/kibana-kb-http 5601:5601 -n elastic-stack
```

Abra `http://localhost:5601`.

### 12.3 Senha do usuario `elastic`

```bash
kubectl get secret elasticsearch-es-elastic-user -n elastic-stack \
  -o jsonpath="{.data.elastic}" | base64 -d && echo
```

### 12.4 Evidencia dos logs

No Kibana, use `Discover` e filtre por namespace `sock-shop` ou `apm-demo`.

## 13. Validacao do Elastic APM

### 13.1 Verifique a app

```bash
kubectl get pods -n apm-demo
kubectl port-forward svc/apm-demo 3001:3000 -n apm-demo
```

### 13.2 Gere trafego

```bash
curl http://localhost:3001/
curl http://localhost:3001/work?delay=900
curl http://localhost:3001/failure
```

Depois valide no Kibana APM se o servico `aquarela-apm-demo` apareceu.

## 14. Acesso do usuario IAM `desafio_aquarela`

O Terraform cria o usuario IAM e o workflow aplica o `aws-auth` para mapear esse usuario como `system:masters`.

Output util:

```bash
cd terraform/environments/prod
terraform output desafio_aquarela_user_arn
```

Para uso real, ainda sera necessario criar credenciais para esse usuario de acordo com sua politica interna.

## 15. Comandos uteis de troubleshooting

### Reaplicar apenas o ambiente Terraform localmente

```bash
cd terraform/environments/prod
terraform init \
  -backend-config="bucket=aquarela-tf-state" \
  -backend-config="key=environments/prod/terraform.tfstate" \
  -backend-config="region=$AWS_REGION" \
  -backend-config="dynamodb_table=aquarela-tf-locks"
terraform plan
```

### Forcar sincronizacao no Argo CD

```bash
kubectl annotate application sock-shop-core -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl annotate application sock-shop-frontend -n argocd argocd.argoproj.io/refresh=hard --overwrite
```

### Ver logs do Fluent Bit

```bash
kubectl logs -n elastic-stack daemonset/fluent-bit
```

### Ver logs do APM demo

```bash
kubectl logs -n apm-demo deployment/apm-demo
```

## 16. Fechamento da entrega

Ao final, salve evidencias de:

- workflow do GitHub Actions concluido com sucesso
- nodes do EKS
- Argo CD com apps sincronizadas
- Sock Shop acessivel pelo `LoadBalancer`
- dashboard no Grafana
- e-mail do Alertmanager
- logs no Kibana
- traces/transactions no APM

O checklist resumido continua em [docs/evidence-checklist.md](/home/guilhermef/clients/aquarela/docs/evidence-checklist.md).



