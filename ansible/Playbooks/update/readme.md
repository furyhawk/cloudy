# Add to Hosts File (change ansible_user if required)
```
[all:vars]
ansible_user='user'
ansible_become=yes
ansible_become_method=sudo

ansible-playbook site.yaml -i inventory/hosts.ini --key-file ~/.ssh/id_rsa -K
```