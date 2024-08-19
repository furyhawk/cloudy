# osrm

```bash
# This file can update the OSRM Helm chart's default configuration values.
helm repo add hypnoglow https://hypnoglow.github.io/helm-charts/
helm repo update
helm upgrade --cleanup-on-fail \
  --install osrm-be hypnoglow/osrm \
  --namespace osrm-be \
  --create-namespace \
  --values values.yaml
```