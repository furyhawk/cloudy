# talos

```bash
export CONTROL_PLANE_IP=192.168.50.180
# talosctl gen config talos-proxmox-cluster https://$CONTROL_PLANE_IP:6443 --output-dir _out
#customization:
#    systemExtensions:
#        officialExtensions:
#            - siderolabs/amd-ucode
#            - siderolabs/amdgpu-firmware
#            - siderolabs/fuse3
#            - siderolabs/iscsi-tools
#            - siderolabs/qemu-guest-agent
# https://factory.talos.dev/?arch=amd64&cmdline-set=true&extensions=-&extensions=siderolabs%2Famdgpu-firmware&extensions=siderolabs%2Famd-ucode&extensions=siderolabs%2Ffuse3&extensions=siderolabs%2Fiscsi-tools&extensions=siderolabs%2Fqemu-guest-agent&platform=metal&target=metal&version=1.7.5
talosctl gen config talos-proxmox-cluster https://$CONTROL_PLANE_IP:6443 --output-dir _out --install-image factory.talos.dev/installer/770f94a47e708326b61f3e641bb733dc879c544dee1972e74763798fe93a1f6d:v1.7.5 --force
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
k describe daemonset -n metallb-system
# actually apply the changes, returns nonzero returncode on errors only
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb --create-namespace -n 'metallb-system'
# helm install metallb metallb/metallb -f metallb.yaml
kubectl apply -f metallb.yaml

helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik --create-namespace -n 'traefik' -f traefik.yaml
```