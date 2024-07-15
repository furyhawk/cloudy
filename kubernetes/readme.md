# cli

```bash
export K3S_TOKEN=${RANDOM}${RANDOM}${RANDOM}
docker compose -f k3s.yml up -d
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/user-guides/crd-acme/02-services.yml
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/user-guides/crd-acme/03-deployments.yml
kubectl port-forward --address 0.0.0.0 service/traefik 8000:8000 8080:8080 443:4443 -n default
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/user-guides/crd-acme/04-ingressroutes.yml
curl [-k] https://your.example.com/tls
curl http://your.example.com:8000/notls

```