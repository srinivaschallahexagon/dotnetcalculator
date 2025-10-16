#!/bin/bash

# Calculator Web App Build and Deploy Script
# This script builds the Docker image and optionally deploys to various Azure services

set -e  # Exit on any error

# Configuration
IMAGE_NAME="calculator-web-app"
VERSION="latest"
RESOURCE_GROUP="calculator-rg"
ACI_NAME="calculator-aci"
AKS_CLUSTER="calculator-aks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    log_info "Checking Docker..."
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    log_success "Docker is running"
}

# Build the Docker image
build_image() {
    log_info "Building Docker image: $IMAGE_NAME:$VERSION"
    docker build -t "$IMAGE_NAME:$VERSION" .
    if [ $? -eq 0 ]; then
        log_success "Docker image built successfully"
    else
        log_error "Failed to build Docker image"
        exit 1
    fi
}

# Test the image locally
test_image() {
    log_info "Testing Docker image locally..."
    
    # Stop any existing container
    docker stop calculator-test >/dev/null 2>&1 || true
    docker rm calculator-test >/dev/null 2>&1 || true
    
    # Run the container
    docker run -d -p 8081:8080 --name calculator-test "$IMAGE_NAME:$VERSION"
    
    # Wait for the container to start
    sleep 5
    
    # Test health endpoint
    if curl -f http://localhost:8081/health >/dev/null 2>&1; then
        log_success "Health check passed"
        docker stop calculator-test
        docker rm calculator-test
    else
        log_error "Health check failed"
        docker logs calculator-test
        docker stop calculator-test
        docker rm calculator-test
        exit 1
    fi
}

# Tag for Azure Container Registry
tag_for_acr() {
    if [ -z "$ACR_NAME" ]; then
        log_error "ACR_NAME environment variable is not set"
        return 1
    fi
    
    local acr_image="$ACR_NAME.azurecr.io/$IMAGE_NAME:$VERSION"
    log_info "Tagging image for ACR: $acr_image"
    docker tag "$IMAGE_NAME:$VERSION" "$acr_image"
    log_success "Image tagged for ACR"
    echo "$acr_image"
}

# Push to Azure Container Registry
push_to_acr() {
    local acr_image=$(tag_for_acr)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    log_info "Pushing to Azure Container Registry..."
    az acr login --name "$ACR_NAME"
    docker push "$acr_image"
    log_success "Image pushed to ACR"
}

# Deploy to Azure Container Instances
deploy_to_aci() {
    local acr_image="$ACR_NAME.azurecr.io/$IMAGE_NAME:$VERSION"
    
    log_info "Deploying to Azure Container Instances..."
    az container create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$ACI_NAME" \
        --image "$acr_image" \
        --registry-login-server "$ACR_NAME.azurecr.io" \
        --registry-username "$ACR_NAME" \
        --registry-password "$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)" \
        --ports 8080 \
        --dns-name-label "calculator-$(date +%s)" \
        --cpu 1 \
        --memory 1 \
        --restart-policy Always
    
    log_success "Deployed to Azure Container Instances"
    
    # Get the FQDN
    local fqdn=$(az container show --resource-group "$RESOURCE_GROUP" --name "$ACI_NAME" --query ipAddress.fqdn -o tsv)
    log_info "Application URL: http://$fqdn:8080"
}

# Deploy to Azure Kubernetes Service
deploy_to_aks() {
    local acr_image="$ACR_NAME.azurecr.io/$IMAGE_NAME:$VERSION"
    
    log_info "Deploying to Azure Kubernetes Service..."
    
    # Get AKS credentials
    az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --overwrite-existing
    
    # Update the deployment YAML with the correct image
    sed "s|calculator-web-app:latest|$acr_image|g" k8s/deployment.yaml > k8s/deployment-temp.yaml
    
    # Apply the deployment
    kubectl apply -f k8s/deployment-temp.yaml
    
    # Wait for deployment to be ready
    kubectl rollout status deployment/calculator-web-app --timeout=300s
    
    # Clean up temp file
    rm k8s/deployment-temp.yaml
    
    log_success "Deployed to Azure Kubernetes Service"
    
    # Get the external IP (may take a few minutes)
    log_info "Waiting for LoadBalancer IP..."
    kubectl get service calculator-web-service
}

# Show usage
show_usage() {
    echo "Calculator Web App Build and Deploy Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  build           Build Docker image"
    echo "  test            Build and test Docker image locally"
    echo "  acr             Build, test, and push to Azure Container Registry"
    echo "  aci             Build, test, push to ACR, and deploy to Azure Container Instances"
    echo "  aks             Build, test, push to ACR, and deploy to Azure Kubernetes Service"
    echo "  all             Run all steps (build, test, ACR, ACI, AKS)"
    echo "  help            Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  ACR_NAME        Azure Container Registry name (required for ACR operations)"
    echo "  RESOURCE_GROUP  Azure Resource Group (default: calculator-rg)"
    echo "  ACI_NAME        Azure Container Instance name (default: calculator-aci)"
    echo "  AKS_CLUSTER     Azure Kubernetes Service cluster name (default: calculator-aks)"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  ACR_NAME=myregistry $0 acr"
    echo "  ACR_NAME=myregistry RESOURCE_GROUP=myrg $0 aci"
}

# Main script logic
main() {
    case "${1:-help}" in
        "build")
            check_docker
            build_image
            ;;
        "test")
            check_docker
            build_image
            test_image
            ;;
        "acr")
            check_docker
            build_image
            test_image
            push_to_acr
            ;;
        "aci")
            check_docker
            build_image
            test_image
            push_to_acr
            deploy_to_aci
            ;;
        "aks")
            check_docker
            build_image
            test_image
            push_to_acr
            deploy_to_aks
            ;;
        "all")
            check_docker
            build_image
            test_image
            push_to_acr
            deploy_to_aci
            deploy_to_aks
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

# Run the main function
main "$@"