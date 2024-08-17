# plane

```bash
helm repo add makeplane https://helm.plane.so/
helm repo update
helm install plane-app makeplane/plane-ce \
    --create-namespace \
    --namespace plane-ce \
    -f values.yaml \
    --timeout 10m \
    --wait \
    --wait-for-jobs 
```