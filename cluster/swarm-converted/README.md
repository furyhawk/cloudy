# Swarm To Kubernetes Conversion

This directory contains a first-pass Kubernetes conversion of the main Swarm application stacks from:

- `swarm/core.yml`
- `swarm/services.yml`
- `swarm/apps.yml`

Scope and assumptions:

- The conversion targets the core public-facing services, not every file under `swarm/`.
- Swarm-only constructs such as overlay networks, placement constraints, and `deploy.labels` were mapped into Kubernetes `Service`, `Deployment`, `PersistentVolumeClaim`, `IngressRoute`, and `Middleware` resources.
- Resource names use Kubernetes-safe hyphenated names where Swarm used underscores.
- Public routes keep Traefik semantics through Traefik CRDs, so the cluster must already have Traefik and its CRDs installed.
- `LOCALDOMAIN` routes were intentionally omitted.
- Persistent host paths from Swarm were converted to PVCs so the manifests are more portable.
- The Traefik Swarm deployment itself was not copied directly; this directory assumes a Kubernetes Traefik controller already exists.

Before applying:

1. Replace every `REPLACE_DOMAIN` placeholder.
2. Review `01-config.yaml` and set real secrets.
3. Review PVC sizing and storage classes in `03-storage.yaml`.
4. Confirm Traefik entry points `websecure` and `postgres` exist in the cluster.

Suggested apply order:

```bash
kubectl apply -f cluster/swarm-converted/00-namespace.yaml
kubectl apply -f cluster/swarm-converted/01-config.yaml
kubectl apply -f cluster/swarm-converted/02-traefik.yaml
kubectl apply -f cluster/swarm-converted/03-storage.yaml
kubectl apply -f cluster/swarm-converted/10-services-stack.yaml
kubectl apply -f cluster/swarm-converted/11-apps-stack.yaml
```

Useful checks:

```bash
kubectl get all -n swarm-converted
kubectl get ingressroute,ingressroutetcp,middleware -n swarm-converted
kubectl describe pod -n swarm-converted
```
