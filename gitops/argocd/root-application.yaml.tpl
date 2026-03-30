apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aquarela-root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: __REPO_URL__
    targetRevision: HEAD
    path: gitops/argocd/apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
