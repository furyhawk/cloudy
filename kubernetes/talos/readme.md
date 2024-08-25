# talos

```bash
export CONTROL_PLANE_IP=192.168.50.180
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

talosctl gen config talos-proxmox-cluster https://$CONTROL_PLANE_IP:6443 --output-dir _out --install-image factory.talos.dev/installer/fd65c64ea210a46f2dfbd101075a9e0c4380d286e92c202bb42c5a7e67047c77:v1.7.6 --force
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
helm install longhorn longhorn/longhorn --create-namespace -n 'longhorn-system' -f longhorn.yaml

helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik --create-namespace -n 'traefik' -f traefik.yaml
```