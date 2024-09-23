# Ansible

## Update all packages
```bash
ansible-playbook -i inventory playbooks/update/update-noreboot.yml -l '!dc08' -K
ansible-playbook -i inventory playbooks/update/update-noreboot.yml -l 'prod' -K
```