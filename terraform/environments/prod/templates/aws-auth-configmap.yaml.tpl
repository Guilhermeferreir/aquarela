apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: __DESAFIO_AQUARELA_USER_ARN__
      username: desafio_aquarela
      groups:
        - system:masters
