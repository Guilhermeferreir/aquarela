# Checklist de evidencias

## 1. Terraform e EKS

- `terraform plan` sem erros.
- `terraform apply` concluido.
- `aws eks describe-cluster --name aquarela-prod-eks --region <REGION>`
- `kubectl get nodes`

## 2. Sock Shop

- `kubectl get pods -n sock-shop`
- `kubectl get svc front-end -n sock-shop`
- Captura da URL externa do `LoadBalancer`.
- Tela do frontend acessivel pelo navegador.

## 3. Prometheus e Grafana

- `kubectl get pods -n monitoring`
- `kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring`
- `kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring`
- Captura do dashboard com metricas do namespace `sock-shop`.
