#!/bin/bash

# Cloud Native Gauntlet - Simplified Setup Script
# Sets up K3s cluster with master and worker nodes using Terraform and Ansible

set -e
trap cleanup ERR SIGINT SIGTERM

echo "Starting Cloud Native Gauntlet Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Terraform
    if ! command -v terraform >/dev/null 2>&1; then
        print_error "Terraform is required but not installed."
        print_status "Install Terraform:"
        if [[ "$OS" == "macos" ]]; then
            echo "  brew install terraform"
        else
            echo "  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -"
            echo "  sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com \$(lsb_release -cs)\""
            echo "  sudo apt-get update && sudo apt-get install terraform"
        fi
        exit 1
    fi
    
    # Check Ansible
    if ! command -v ansible >/dev/null 2>&1; then
        print_error "Ansible is required but not installed."
        print_status "Install Ansible:"
        if [[ "$OS" == "macos" ]]; then
            echo "  brew install ansible"
        else
            echo "  sudo apt update && sudo apt install ansible"
        fi
        exit 1
    fi
    
    # Check jq for JSON parsing
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq is required but not installed."
        if [[ "$OS" == "macos" ]]; then
            echo "  brew install jq"
        else
            echo "  sudo apt install jq"
        fi
        exit 1
    fi
    
    # Check if SSH key exists
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        print_error "SSH public key not found at ~/.ssh/id_rsa.pub"
        print_status "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    print_status "All prerequisites are satisfied!"
}

# Create infrastructure with Terraform
create_infrastructure() {
    print_status "Creating infrastructure..."
    cd infra/terraform
    terraform init
    terraform apply -auto-approve

    cd ../..
}

# Update Ansible inventory
update_inventory() {
    print_status "Updating Ansible inventory..."
    cd infra/terraform
    local VM_IPS=$(terraform output -json vm_ips)
    local MASTER_IP=$(echo "$VM_IPS" | jq -r '.master')
    local WORKER_IP=$(echo "$VM_IPS" | jq -r '.worker')
    local REGISTRY_IP=$(echo "$VM_IPS" | jq -r '.registry')
    cd ../ansible
    cat > inventory.ini << EOF
[master]
k3s-master ansible_host=$MASTER_IP ansible_user=ubuntu

[workers]
k3s-worker ansible_host=$WORKER_IP ansible_user=ubuntu

[registry]
docker-registry ansible_host=$REGISTRY_IP ansible_user=ubuntu

[k3s:children]
master
workers

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
registry_host=$REGISTRY_IP
registry_port=5000
EOF

    print_status "Ansible inventory updated!"
    cd ../..
}

# Set up SSH access to VMs
setup_ssh_access() {
    print_status "Setting up SSH access..."
    cd infra/terraform
    local VM_IPS=$(terraform output -json vm_ips)
    cd ../..
    local NODES=("k3s-master" "k3s-worker" "docker-registry")
    local IPS=(
        $(echo "$VM_IPS" | jq -r '.master')
        $(echo "$VM_IPS" | jq -r '.worker')
        $(echo "$VM_IPS" | jq -r '.registry')
    )
    for i in "${!NODES[@]}"; do
        local NODE=${NODES[$i]}
        local IP=${IPS[$i]}

        print_status "Copying SSH key to $NODE ($IP)..."
        multipass exec $NODE -- mkdir -p /home/ubuntu/.ssh
        cat ~/.ssh/id_rsa.pub | multipass exec $NODE -- tee -a /home/ubuntu/.ssh/authorized_keys
        multipass exec $NODE -- chmod 700 /home/ubuntu/.ssh
        multipass exec $NODE -- chmod 600 /home/ubuntu/.ssh/authorized_keys
    done
}

# Mount project directory to master VM
mount_project_directory() {
    print_status "Mounting project directory..."
    local PROJECT_DIR=$(pwd)
    multipass info k3s-master | grep -q "/home/ubuntu/projects" || {
        multipass mount "$PROJECT_DIR" k3s-master:/home/ubuntu/projects
    }
}

# Run Ansible provisioning
run_ansible_provisioning() {
    print_status "Running Ansible provisioning..."
    cd infra/ansible
    ansible-playbook -i inventory.ini configure-k3s.yml setup-registry.yml -v|| {
        print_error "K3s provisioning failed!"
        exit 1
    }
    cd ../..
}

# Wait for cluster readiness
wait_for_cluster() {
    print_status "Waiting for cluster..."
    cd infra/terraform
    local MASTER_IP=$(terraform output -json vm_ips | jq -r '.master')
    cd ../..
    for i in {1..30}; do
        if ssh -o StrictHostKeyChecking=no ubuntu@$MASTER_IP "kubectl --kubeconfig /home/ubuntu/.kube/config get nodes 2>/dev/null | grep -q 'Ready'" 2>/dev/null; then
            local NODE_COUNT=$(ssh -o StrictHostKeyChecking=no ubuntu@$MASTER_IP "kubectl --kubeconfig /home/ubuntu/.kube/config get nodes --no-headers 2>/dev/null | wc -l")
            [[ "$NODE_COUNT" -eq 2 ]] && break
        fi
        sleep 10
    done
}

# Show cluster information
show_cluster_info() {
    print_status "Setup completed!"
    cd infra/terraform
    local VM_IPS=$(terraform output -json vm_ips)
    local MASTER_IP=$(echo "$VM_IPS" | jq -r '.master')
    local WORKER_IP=$(echo "$VM_IPS" | jq -r '.worker')
    cd ../..
    echo -e "\nAccess Information:"
    echo "=================="
    echo "Master IP: $MASTER_IP"
    echo "Worker IP: $WORKER_IP"
    echo "Cluster Status: ssh ubuntu@$MASTER_IP 'kubectl get nodes'"
    echo "Deploy Apps: ./scripts/deploy.sh"
}

# Cleanup on error or interruption
cleanup() {
    print_error "Setup failed. Cleaning up..."
    cd infra/terraform
    terraform destroy -auto-approve || true
    cd ../..
    exit 1
}

# Main execution
main() {
    echo "=========================================="
    echo "   Cloud Native Gauntlet Setup Script"
    echo "=========================================="
    echo ""
    check_prerequisites
    create_infrastructure
    update_inventory
    setup_ssh_access
    mount_project_directory
    run_ansible_provisioning
    wait_for_cluster
    show_cluster_info
}

main "$@"