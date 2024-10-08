# talos

```bash
export CONTROL_PLANE_IP=192.168.50.191
# talosctl gen config talos-proxmox-cluster https://$CONTROL_PLANE_IP:6443 --output-dir _out

# amd
# customization:
#     systemExtensions:
#         officialExtensions:
#             - siderolabs/amd-ucode
#             - siderolabs/amdgpu-firmware
#             - siderolabs/fuse3
#             - siderolabs/iscsi-tools
#             - siderolabs/qemu-guest-agent
#             - siderolabs/realtek-firmware
#             - siderolabs/util-linux-tools
# https://factory.talos.dev/?arch=amd64&board=undefined&cmdline-set=true&extensions=-&extensions=siderolabs%2Famdgpu-firmware&extensions=siderolabs%2Famd-ucode&extensions=siderolabs%2Ffuse3&extensions=siderolabs%2Fiscsi-tools&extensions=siderolabs%2Fqemu-guest-agent&extensions=siderolabs%2Frealtek-firmware&extensions=siderolabs%2Futil-linux-tools&platform=metal&secureboot=undefined&target=metal&version=1.7.6
30b52fe0b834407cbb71df89b889708e82700fa6771fed78b13f1ff7b02398fd

# intel
Schematic Ready
Your image schematic ID is: fd65c64ea210a46f2dfbd101075a9e0c4380d286e92c202bb42c5a7e67047c77
customization:
    systemExtensions:
        officialExtensions:
            - siderolabs/fuse3
            - siderolabs/i915-ucode
            - siderolabs/intel-ucode
            - siderolabs/iscsi-tools
            - siderolabs/qemu-guest-agent
            - siderolabs/realtek-firmware
            - siderolabs/tailscale
            - siderolabs/util-linux-tools
            - siderolabs/zfs
https://factory.talos.dev/?arch=amd64&board=undefined&cmdline-set=true&extensions=-&extensions=siderolabs%2Ffuse3&extensions=siderolabs%2Fi915-ucode&extensions=siderolabs%2Fintel-ucode&extensions=siderolabs%2Fiscsi-tools&extensions=siderolabs%2Fqemu-guest-agent&extensions=siderolabs%2Frealtek-firmware&extensions=siderolabs%2Ftailscale&extensions=siderolabs%2Futil-linux-tools&extensions=siderolabs%2Fzfs&platform=metal&secureboot=undefined&target=metal&version=1.7.6

factory.talos.dev/installer/fd65c64ea210a46f2dfbd101075a9e0c4380d286e92c202bb42c5a7e67047c77:v1.7.6

arm64
https://factory.talos.dev/?arch=arm64&cmdline-set=true&extensions=-&extensions=siderolabs%2Ffuse3&extensions=siderolabs%2Fiscsi-tools&extensions=siderolabs%2Fqemu-guest-agent&extensions=siderolabs%2Futil-linux-tools&platform=metal&target=metal&version=1.7.6
factory.talos.dev/installer/039a705a9d120fab2ce1931cbdfbdeeb3c6bfe5c2a0e26479772406cc769943e:v1.7.6

talosctl upgrade --nodes 192.168.50.191,192.168.50.192,192.168.50.193 --image factory.talos.dev/installer/039a705a9d120fab2ce1931cbdfbdeeb3c6bfe5c2a0e26479772406cc769943e:v1.7.6 --preserve

talosctl gen config talos-arm-cluster https://$CONTROL_PLANE_IP:6443 --output-dir _out --install-image factory.talos.dev/installer/fd65c64ea210a46f2dfbd101075a9e0c4380d286e92c202bb42c5a7e67047c77:v1.7.6 --force
talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file _out/controlplane.yaml
export TALOSCONFIG="_out/talosconfig"
# talosctl config merge $TALOSCONFIG
talosctl config endpoint $CONTROL_PLANE_IP --talosconfig $TALOSCONFIG
talosctl config node $CONTROL_PLANE_IP --talosconfig $TALOSCONFIG
talosctl bootstrap --talosconfig $TALOSCONFIG
talosctl health
talosctl kubeconfig .
talosctl apply-config --insecure --nodes 192.168.50.185 --file _out/worker.yaml

KUBE_EDITOR="nano" kubectl edit configmap -n kube-system kubeconfig-in-cluster
KUBE_EDITOR="nano" kubectl edit configmap -n kube-system kube-proxy
kubectl create namespace metallb-system
kubectl label namespaces metallb-system pod-security.kubernetes.io/enforce=privileged --overwrite=true
kubectl label namespaces metallb-system pod-security.kubernetes.io/audit=privileged --overwrite=true
kubectl label namespaces metallb-system pod-security.kubernetes.io/warn=privileged --overwrite=true
# actually apply the changes, returns nonzero returncode on errors only
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install metallb metallb/metallb --create-namespace -n 'metallb-system'
# helm install metallb metallb/metallb -f metallb.yaml
kubectl apply -f metallb.yaml
k describe daemonset -n metallb-system

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io --force-update
helm install cert-manager --namespace cert-manager --version v1.15.3 jetstack/cert-manager --create-namespace

# NAME: cert-manager
LAST DEPLOYED: Sun Aug 25 00:23:04 2024
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
cert-manager v1.15.3 has been deployed successfully!

In order to begin issuing certificates, you will need to set up a ClusterIssuer
or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).

More information on the different types of issuers and how to configure them
can be found in our documentation:

https://cert-manager.io/docs/configuration/

For information on how to configure cert-manager to automatically provision
Certificates for Ingress resources, take a look at the `ingress-shim`
documentation:

helm repo add longhorn https://charts.longhorn.io
helm repo update
kubectl create namespace longhorn-system
kubectl apply -f longhorn.yaml
helm install longhorn longhorn/longhorn --namespace longhorn-system
# helm install longhorn longhorn/longhorn --create-namespace -n 'longhorn-system' -f longhorn.yaml

helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik --create-namespace -n 'traefik' -f traefik.yaml

# Add kubernetes-dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
# Release "kubernetes-dashboard" does not exist. Installing it now.
# NAME: kubernetes-dashboard
# LAST DEPLOYED: Sun Sep 15 23:12:56 2024
# NAMESPACE: kubernetes-dashboard
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# *************************************************************************************************
# *** PLEASE BE PATIENT: Kubernetes Dashboard may need a few minutes to get up and become ready ***
# *************************************************************************************************

# Congratulations! You have just installed Kubernetes Dashboard in your cluster.

# To access Dashboard run:
#   kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443

# NOTE: In case port-forward command does not work, make sure that kong service name is correct.
#       Check the services in Kubernetes Dashboard namespace using:
#         kubectl -n kubernetes-dashboard get svc

# Dashboard will be available at:
#   https://localhost:8443


# Create a service account for the dashboard
kubectl apply -f dashboard-adminuser.yaml
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d

# kubectl  -n kubernetes-dashboard create serviceaccount admin-user
# serviceaccount/kubernetes-dashboard created
kubectl -n kubernetes-dashboard create token admin-user

```

## Uninstallation

```bash
helm uninstall traefik -n traefik
helm uninstall longhorn -n longhorn-system
helm uninstall cert-manager -n cert-manager
helm uninstall metallb -n metallb-system
helm uninstall kubernetes-dashboard -n kubernetes-dashboard

Uninstallation
kubectl -n longhorn-system patch -p '{"value": "true"}' --type=merge lhs deleting-confirmation-flag
helm uninstall longhorn -n longhorn-system
kubectl delete namespace longhorn-system
```