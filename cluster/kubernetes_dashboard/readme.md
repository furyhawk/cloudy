# kubenetes dashboard
# https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
# https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
# kubectl proxy
```
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard -f values.yaml
kubectl -n kubernetes-dashboard apply -f ingress-route.yaml
# Create a service account for the dashboard
kubectl apply -f dashboard-adminuser.yaml
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
kubectl -n kubernetes-dashboard create token admin-user
# kubectl -n kubernetes-dashboard apply -f dashboard-ingress-route.yaml

kubectl -n kubernetes-dashboard get ingressroutes

k delete -f ingress-route.yaml
# k delete -f dashboard-ingress-route.yaml
kubectl -n kubernetes-dashboard delete serviceaccount admin-user
kubectl -n kubernetes-dashboard delete clusterrolebinding admin-user
helm delete kubernetes-dashboard --namespace kubernetes-dashboard
```
