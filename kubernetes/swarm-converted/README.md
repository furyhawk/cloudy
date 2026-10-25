# Swarm To Kubernetes Stack (Phased)

This folder duplicates the Swarm stack conversion into the `kubernetes/` path so it can be managed as a Kubernetes-first stack.

Converted stack sources:

- `swarm/core.yml`
- `swarm/services.yml`
- `swarm/apps.yml`

## Phase 1: setup

Apply foundational resources first:

- namespace
- shared config and secrets template
- Traefik middlewares
- persistent volume claims

```bash
kubectl apply -k kubernetes/swarm-converted/phases/setup
```

## Phase 2: up

Apply workloads after setup:

- services stack workloads
- apps stack workloads

```bash
kubectl apply -k kubernetes/swarm-converted/phases/up
```

## Pre-flight checklist

1. Replace `REPLACE_DOMAIN` placeholders.
2. Set real credentials/secrets in `01-config.yaml`.
3. Validate PVC sizing/storage class behavior in `03-storage.yaml`.
4. Confirm Traefik CRDs and entrypoints (`websecure`, `postgres`) exist.

## Running on a VM in a local network

This stack can run on a LAN VM as long as clients can resolve your chosen domain to the VM IP (or to your ingress LB IP).

### 1) Pick a LAN domain and VM IP

Example:

- Domain: `cloudy.home.arpa`
- VM IP: `192.168.1.50`

Use a domain dedicated to local use (`home.arpa`) to avoid conflicts with public DNS.

### 2) Configure local DNS

Preferred (works for all listed apps): create wildcard DNS records on your local DNS server (router DNS, Pi-hole, AdGuard Home, or dnsmasq):

- `A cloudy.home.arpa -> 192.168.1.50`
- `A *.cloudy.home.arpa -> 192.168.1.50`

If your DNS server does not support wildcard records, add explicit host records for the subdomains used by this stack:

- `api`, `drive`, `storage`, `minio`, `s3`, `osrm`, `whoami`
- `adminer`, `dbadmin`, `cheat`, `bai`, `fin`, `media`, `mesh`
- `n`, `note`, `note0`, `pad`, `paste`, `bin`, `info`, `www`, `resume`, `blog`, `124c41`

Each record should point to the same VM IP (or ingress LoadBalancer IP).

### 3) Ensure ingress is reachable on the VM

Make sure your Kubernetes ingress controller (Traefik) is reachable from LAN clients on 80/443.

Common patterns:

- k3s default Traefik listening on VM node IP.
- Traefik Service type `LoadBalancer` with MetalLB.
- Traefik Service type `NodePort` and clients using `http(s)://<domain>:<nodeport>` if 80/443 is not directly exposed.

### 4) Replace domain placeholders in manifests

From repo root:

```bash
perl -pi -e 's/REPLACE_DOMAIN/cloudy.home.arpa/g' kubernetes/swarm-converted/phases/setup/*.yaml kubernetes/swarm-converted/phases/up/*.yaml
```

### 5) Deploy by phase

```bash
make k8s-setup
make k8s-up
```

### 6) Verify from a LAN client

```bash
kubectl get ingressroute -n swarm-converted
curl -I https://api.cloudy.home.arpa
curl -I https://cloudy.home.arpa
```

## Useful checks

```bash
kubectl get all -n swarm-converted
kubectl get ingressroute,ingressroutetcp,middleware -n swarm-converted
kubectl describe pod -n swarm-converted
```
