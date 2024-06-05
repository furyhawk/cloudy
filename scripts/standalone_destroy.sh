#!/bin/bash
set -x
fsid="$1"
cephadm rm-cluster --fsid $fsid --force
source /etc/os-release
sudo systemctl stop tripleo_\*
sudo systemctl stop ceph\*
sudo pcs cluster destroy
if [ $VERSION_ID == "7" ]; then
  sudo docker ps -a -q | xargs docker rm -f
else
  sudo podman rm --all
  sudo podman rm --all -f
  sudo podman rmi -af
fi

sudo rm -rf /var/lib/mysql \
    /var/lib/rabbitmq \
    /var/lib/config-data \
    /etc/puppet/hieradata \
    /var/log/containers \
    /var/lib/tripleo-config \
    /var/lib/config-data /var/lib/container-config-scripts \
    /var/lib/container-puppet \
    /var/lib/heat-config \
    /var/lib/image-serve \
    /var/lib/containers \
    /etc/systemd/system/tripleo*

sudo systemctl daemon-reload

# remove ceph directories
sudo rm -rf \
     /var/log/ceph \
     /var/run/ceph \
     /var/lib/ceph \
     /run/ceph \
     /etc/ceph/*

# steps to destroy ceph lv
sudo lvremove --force /dev/ceph_vg/ceph_lv_wal
sudo lvremove --force /dev/ceph_vg/ceph_lv_db
sudo lvremove --force /dev/ceph_vg/ceph_lv_data
sudo vgremove --force ceph_vg
sudo pvremove --force /dev/loop4
sudo losetup -d /dev/loop2
sudo rm -f /var/lib/ceph-osd.img
sudo partprobe

# steps to recreate ceph stuff
sudo dd if=/dev/zero of=/var/lib/ceph-osd.img bs=1 count=0 seek=14G
sudo losetup /dev/loop2 /var/lib/ceph-osd.img
sudo vgcreate ceph_vg /dev/loop2
sudo lvcreate -n ceph_lv_wal -l 375 ceph_vg
sudo lvcreate -n ceph_lv_db -l 375 ceph_vg
sudo lvcreate -n ceph_lv_data -l 2041 ceph_vg
sudo partprobe