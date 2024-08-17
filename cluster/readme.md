# kubunetes cluster

## Create a cluster
```bash
```

## Delete a cluster
```bash
```

## Get cluster info
```bash
```

## Get cluster status
```bash
```

## Get cluster logs
```bash
```

## Get cluster events
```bash
```

## Get cluster nodes
```bash
```

## Delete rancher

### Using the cleanup script
Run as a Kubernetes Job
```bash
k create -f rancher-cleanup.yaml
kubectl  -n kube-system logs -l job-name=cleanup-job  -f
```

Verify that the job has completed
```bash
kubectl apply -f verify.yaml
kubectl  -n kube-system logs -l job-name=verify-job  -f
kubectl  -n kube-system logs -l job-name=verify-job  -f | grep -v "is deprecated"
```
