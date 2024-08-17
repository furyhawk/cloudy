# Ngnix Ingress

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx ingress-nginx/ingress-nginx \
    --create-namespace \
    --namespace nginx-system

```