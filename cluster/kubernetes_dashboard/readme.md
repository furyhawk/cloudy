# kubenetes dashboard
# https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

# kubectl proxy
```
kubectl -n kubernetes-dashboard apply -f dashboard-ingress-route.yaml

kubectl -n kubernetes-dashboard get ingressroutes


k delete -f dashboard-ingress-route.yaml
```
