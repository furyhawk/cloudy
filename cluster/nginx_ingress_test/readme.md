# nginx_ingress_test stack

```bash
minikube start
k create ns nginx_ingress_test
kubectl config set-context --current --namespace=nginx_ingress_test

# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
minikube addons enable ingress

k apply -f nginx_ingress_test
minikube ip

minikube tunnel 

# Wait for ingress address

# kubectl get ingress
# NAME              CLASS   HOSTS   ADDRESS          PORTS   AGE
# example-ingress   nginx   *       <your_ip_here>   80      5m45s

# Note for Docker Desktop Users:
# To get ingress to work you’ll need to open a new terminal window and run minikube tunnel and in the following step use 127.0.0.1 in place of <ip_from_above>.

minikube delete --all --purge


```