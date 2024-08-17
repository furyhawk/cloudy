# traefik ingress route

## Description
```bash
k apply -f ingress_route.yaml -f whoami.yaml
http://test.traefik.local/bar
k delete -f ingress_route.yaml -f whoami.yaml
```