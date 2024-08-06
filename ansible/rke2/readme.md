# RKE2 playbook

/etc/hosts
```
127.0.0.1       localhost
127.0.1.1       c1.local        c1

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```


```bash
export LC_ALL=en_US.UTF-8
ansible-playbook site.yaml -i inventory/hosts.ini --key-file ~/.ssh/id_rsa -K
k get pods --all-namespaces
kubectl create namespace cattle-system
# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.crds.yaml
# install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.2 \
  --set crds.enabled=true
```
NAME: cert-manager
LAST DEPLOYED: Sat Aug  3 21:38:31 2024
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
cert-manager v1.15.2 has been deployed successfully!

In order to begin issuing certificates, you will need to set up a ClusterIssuer
or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).

More information on the different types of issuers and how to configure them
can be found in our documentation:

https://cert-manager.io/docs/configuration/

For information on how to configure cert-manager to automatically provision
Certificates for Ingress resources, take a look at the `ingress-shim`
documentation:

https://cert-manager.io/docs/usage/ingress/


https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/rancher-v2-8-5/
```bash
kubectl get pods --namespace cert-manager
kubectl create namespace cattle-system
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm install rancher rancher-latest/rancher \
 --namespace cattle-system \
 --set hostname=rancher.local \
 --set bootstrapPassword=admin
```
If you provided your own bootstrap password during installation, browse to https://rancher.local to get started.

If this is the first time you installed Rancher, get started by running this command and clicking the URL it generates:

```
echo https://rancher.local/dashboard/?setup=$(kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}')
```
https://node03/dashboard/?setup=admin

To get just the bootstrap password on its own, run:

```
kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{ "\n" }}'
```

```bash
sudo service open-iscsi status
sudo apt install open-iscsi
kubectl -n cattle-system get deploy rancher

kubectl -n cattle-system rollout status deploy/rancher
kubectl -n cattle-system get deploy rancher
kubectl get svc -n cattle-system
kubectl expose deployment rancher --name=rancher-lb --port=443 --type=LoadBalancer -n cattle-system
kubectl get svc -n cattle-system
# kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.2/deploy/longhorn.yaml
# k delete -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.2/deploy/longhorn.yaml
helm repo add longhorn https://charts.longhorn.io
helm repo update
k apply -f longhorn.yaml
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version 1.6.2
kubectl get pods \
--namespace longhorn-system \
--watch
kubectl -n longhorn-system get pod
kubectl get svc
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.1/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.1/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik --create-namespace -n 'traefik' -f traefik.yaml
helm list -n traefik
kubectl -n traefik port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name -A) 9000:9000 --address 0.0.0.0
# Update repository
helm repo update
# See current Chart & Traefik version
helm search repo traefik/traefik
# Update CRDs (Traefik Proxy v3 CRDs)
kubectl apply --server-side --force-conflicts -k https://github.com/traefik/traefik-helm-chart/traefik/crds/
# Upgrade Traefik
helm upgrade traefik traefik/traefik
```