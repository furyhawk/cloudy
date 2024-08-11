# test stack

```bash
k create ns test
kubectl config set-context --current --namespace=test
k apply -f api-deployment.yaml -f client-deployment.yaml
k apply -f database-persistent-volume-claim.yaml
k apply -f api-cluster-ip-service.yaml
k apply -f client-cluster-ip-deployment.yaml
k apply -f postgres-cluster-ip-service.yaml
k apply -f ingress-service.yaml
```