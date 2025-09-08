# Terraform (Multipass VMs)

Creates Multipass VMs for K3s master/worker and a registry node. Outputs IPs consumed by Ansible and scripts.

## Usage
```bash
terraform init
terraform apply -auto-approve
terraform output -json vm_ips | jq
```

## Outputs
- master: master VM IP
- worker: worker VM IP
- registry: local registry VM IP

Used by:
- scripts/setup.sh (inventory generation, SSH setup)
- scripts/deploy.sh (resolves master/registry IPs)