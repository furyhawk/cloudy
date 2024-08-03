#!/bin/bash

echo "Removing old talos configuration files"
rm talosconfig kubeconfig controlplane.yaml worker.yaml 

echo "Setting ip-addresses to NODE* variables"
NODE1=$(virsh domifaddr talos_control-plane-node-1|grep ipv4 |awk '{ print $4 }' | cut -d/ -f1)
echo "NODE1 is ${NODE1}"
NODE2=$(virsh domifaddr talos_control-plane-node-2|grep ipv4 |awk '{ print $4 }' | cut -d/ -f1)
echo "NODE2 is ${NODE2}"
NODE3=$(virsh domifaddr talos_control-plane-node-3|grep ipv4 |awk '{ print $4 }' | cut -d/ -f1)
echo "NODE3 is ${NODE3}"
NODE4=$(virsh domifaddr talos_worker-node-1|grep ipv4 |awk '{ print $4 }' | cut -d/ -f1)
echo "NODE4 is ${NODE4}"
NODE5=$(virsh domifaddr talos_worker-node-2|grep ipv4 |awk '{ print $4 }' | cut -d/ -f1)
echo "NODE5 is ${NODE5}"
NODE6=$(virsh domifaddr talos_worker-node-3|grep ipv4 |awk '{ print $4 }' | cut -d/ -f1)
echo "NODE6 is ${NODE6}"

echo "Check disk type on NODE1"
talosctl -n ${NODE1} disks --insecure

echo "Generating new talos kubernetes cluster configuration"
talosctl gen config my-cluster https://192.168.121.5:6443 --install-disk /dev/vda \
  --config-patch @all.yaml \
  --config-patch-control-plane @../../cp.yaml \
  --config-patch-worker @../../wk.yaml

echo "Applying config to NODE1"
talosctl -n ${NODE1} apply-config --insecure --file controlplane.yaml

echo "Exporting TALOSCONFIG"
export TALOSCONFIG=$(realpath ./talosconfig)

echo "Settings endpoints"
talosctl config endpoint ${NODE1} ${NODE2} ${NODE3} ${NODE4} ${NODE5} ${NODE6}

echo "Bootstrap NODE1"
talosctl -n ${NODE1} bootstrap

echo "Apply config on control-planes nodes NODE2, NODE3"
talosctl -n ${NODE2} apply-config --insecure --file controlplane.yaml
talosctl -n ${NODE3} apply-config --insecure --file controlplane.yaml

echo "Apply config on worker nodes NODE4, NODE5"
talosctl -n ${NODE4} apply-config --insecure --file worker.yaml
talosctl -n ${NODE5} apply-config --insecure --file worker.yaml
talosctl -n ${NODE6} apply-config --insecure --file worker.yaml

echo "Get talos cluster members"
talosctl -n ${NODE1} get members

echo "Generating kubeconfig file"
talosctl -n ${NODE1} kubeconfig ./kubeconfig

echo "Exporting KUBECONFIG"
export KUBECONFIG=$(realpath ./kubeconfig)

echo "Get kubernetes cluster list of nodes"
kubectl get node -owide

echo "Installing cilium cni."
kubectl apply -f ./cilium.yaml

echo "Looking for pod status."
kubectl -n kube-system get pods

echo "Installing metallb."
kubectl apply -f ../../manifests/metallb-native.yaml

echo "Wait until all metallb pods will be ready."
kubectl -n metallb-system get pods

echo "Setup ip address pool."
kubectl apply -f ../../manifests/metallb-addresses.yaml

echo "Installing traefik ingress controller."
kubectl create ns traefik
kubectl -n traefik apply -f ../../manifests/traefik.yaml

echo "Get metallb assigned address for traefik service."
kubectl -n traefik get svc

echo "Ping address and curl webserver on this address."
ping 192.168.121.15 -c 3
curl http://192.168.121.15
