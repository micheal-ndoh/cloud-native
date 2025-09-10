#!/bin/bash

set -euo pipefail

echo "=== Resizing k3s-worker disk from 20G to 30G ==="

# Check if multipass is installed
if ! command -v multipass &> /dev/null; then
    echo "Error: multipass is not installed or not in PATH"
    exit 1
fi

# Check if worker VM exists
if ! multipass list | grep -q "k3s-worker"; then
    echo "Error: k3s-worker VM not found"
    exit 1
fi

echo "Current VM status:"
multipass list | grep k3s-worker

echo ""
echo "Stopping k3s-worker VM..."
multipass stop k3s-worker

echo "Resizing disk to 30G..."
multipass set local.k3s-worker.disk=30G

echo "Starting k3s-worker VM..."
multipass start k3s-worker

echo "Waiting for VM to be ready..."
sleep 10

echo "Expanding filesystem inside the VM..."
multipass exec k3s-worker -- sudo growpart /dev/sda 1
multipass exec k3s-worker -- sudo resize2fs /dev/sda1

echo "Verifying disk space:"
multipass exec k3s-worker -- df -h /

echo ""
echo "Restarting k3s service..."
multipass exec k3s-worker -- sudo systemctl restart k3s-agent

echo "Waiting for k3s-agent to be ready..."
sleep 15

echo "Checking node status:"
kubectl get nodes

echo ""
echo "=== Disk resize completed successfully! ==="
echo "Worker node now has 30G disk space"