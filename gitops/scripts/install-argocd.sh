#!/bin/bash

# Cloud Native Gauntlet - ArgoCD Installation Script
# This script installs ArgoCD for GitOps implementation
# Compatible with macOS and Ubuntu

set -e

echo "Installing ArgoCD for GitOps..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is configured
check_kubectl() {
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "kubectl is not configured or cluster is not accessible"
        print_status "Please run the setup script first: ./scripts/setup.sh"
        exit 1
    fi
    
    print_status "Kubernetes cluster is accessible"
}

# Install ArgoCD
install_argocd() {
    print_status "Installing ArgoCD..."
    
    # Create ArgoCD namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD using the official manifest
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    print_status "ArgoCD installation initiated"
}

# Wait for ArgoCD to be ready
wait_for_argocd() {
    print_status "Waiting for ArgoCD to be ready..."
    
    # Wait for ArgoCD server deployment
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Wait for ArgoCD application controller
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argocd
    
    # Wait for ArgoCD repo server
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd
    
    print_status "ArgoCD is ready"
}

# Install ArgoCD CLI
install_argocd_cli() {
    print_status "Installing ArgoCD CLI..."
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command -v brew &> /dev/null; then
            print_error "Homebrew is required for macOS. Please install it first."
            exit 1
        fi
        brew install argocd
    else
        # Linux (Ubuntu/Debian)
        if ! command -v curl &> /dev/null; then
            print_error "curl is required. Please install it first."
            exit 1
        fi
        
        # Download ArgoCD CLI
        curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
        rm argocd-linux-amd64
    fi
    
    print_status "ArgoCD CLI installed"
}

# Configure ArgoCD
configure_argocd() {
    print_status "Configuring ArgoCD..."
    
    # Get ArgoCD server password
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    # Login to ArgoCD
    argocd login localhost:8080 --username admin --password "$ARGOCD_PASSWORD" --insecure
    
    print_status "ArgoCD configured successfully"
}

# Display ArgoCD information
show_argocd_info() {
    print_status "ArgoCD installation completed successfully!"
    echo ""
    echo "ArgoCD Access Information:"
    echo "=========================="
    
    # Get master IP for external access
    MASTER_IP=$(cd ../../infrastruture/terraform && terraform output -json vm_ips | jq -r '.master' 2>/dev/null || echo "N/A")
    
    echo "ArgoCD Server:"
    echo "- Local: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "- External: https://$MASTER_IP:30005 (if NodePort configured)"
    echo ""
    echo "Default Credentials:"
    echo "- Username: admin"
    echo "- Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
    echo ""
    echo "CLI Commands:"
    echo "- List apps: argocd app list"
    echo "- Get app status: argocd app get <app-name>"
    echo "- Sync app: argocd app sync <app-name>"
    echo ""
    echo "Next Steps:"
    echo "1. Port forward to access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "2. Open browser to: https://localhost:8080"
    echo "3. Login with admin and the password above"
    echo "4. Create applications to deploy your apps via GitOps"
}

# Main execution
main() {
    echo "=========================================="
    echo "   Cloud Native Gauntlet ArgoCD Setup"
    echo "=========================================="
    echo ""
    
    check_kubectl
    install_argocd
    wait_for_argocd
    install_argocd_cli
    configure_argocd
    show_argocd_info
    
    echo "ArgoCD installation completed successfully!"
}

main "$@" 