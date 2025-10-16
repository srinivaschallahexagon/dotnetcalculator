# Calculator Web App Build and Deploy Script (PowerShell)
# This script builds the Docker image and optionally deploys to various Azure services

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("build", "test", "acr", "aci", "aks", "all", "help")]
    [string]$Action = "help",
    
    [Parameter(Mandatory=$false)]
    [string]$AcrName = $env:ACR_NAME,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = $env:RESOURCE_GROUP ?? "calculator-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$AciName = $env:ACI_NAME ?? "calculator-aci",
    
    [Parameter(Mandatory=$false)]
    [string]$AksCluster = $env:AKS_CLUSTER ?? "calculator-aks",
    
    [Parameter(Mandatory=$false)]
    [string]$ImageName = "calculator-web-app",
    
    [Parameter(Mandatory=$false)]
    [string]$Version = "latest"
)

# Color functions
function Write-Info($message) {
    Write-Host "[INFO] $message" -ForegroundColor Blue
}

function Write-Success($message) {
    Write-Host "[SUCCESS] $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "[WARNING] $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

# Check if Docker is running
function Test-Docker {
    Write-Info "Checking Docker..."
    try {
        $null = docker info 2>$null
        Write-Success "Docker is running"
        return $true
    }
    catch {
        Write-Error "Docker is not running. Please start Docker and try again."
        return $false
    }
}

# Build the Docker image
function Build-Image {
    Write-Info "Building Docker image: ${ImageName}:${Version}"
    
    $result = docker build -t "${ImageName}:${Version}" .
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Docker image built successfully"
        return $true
    }
    else {
        Write-Error "Failed to build Docker image"
        return $false
    }
}

# Test the image locally
function Test-Image {
    Write-Info "Testing Docker image locally..."
    
    # Stop any existing container
    docker stop calculator-test 2>$null
    docker rm calculator-test 2>$null
    
    # Run the container
    docker run -d -p 8081:8080 --name calculator-test "${ImageName}:${Version}"
    
    # Wait for the container to start
    Start-Sleep -Seconds 5
    
    # Test health endpoint
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8081/health" -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Success "Health check passed"
            docker stop calculator-test
            docker rm calculator-test
            return $true
        }
    }
    catch {
        Write-Error "Health check failed"
        docker logs calculator-test
        docker stop calculator-test
        docker rm calculator-test
        return $false
    }
}

# Tag for Azure Container Registry
function Add-AcrTag {
    if ([string]::IsNullOrEmpty($AcrName)) {
        Write-Error "ACR_NAME is required for ACR operations"
        return $null
    }
    
    $acrImage = "${AcrName}.azurecr.io/${ImageName}:${Version}"
    Write-Info "Tagging image for ACR: $acrImage"
    docker tag "${ImageName}:${Version}" $acrImage
    Write-Success "Image tagged for ACR"
    return $acrImage
}

# Push to Azure Container Registry
function Push-ToAcr {
    $acrImage = Add-AcrTag
    if ($null -eq $acrImage) {
        return $false
    }
    
    Write-Info "Pushing to Azure Container Registry..."
    az acr login --name $AcrName
    
    if ($LASTEXITCODE -eq 0) {
        docker push $acrImage
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Image pushed to ACR"
            return $true
        }
    }
    
    Write-Error "Failed to push image to ACR"
    return $false
}

# Deploy to Azure Container Instances
function Deploy-ToAci {
    $acrImage = "${AcrName}.azurecr.io/${ImageName}:${Version}"
    
    Write-Info "Deploying to Azure Container Instances..."
    
    # Get ACR password
    $acrPassword = az acr credential show --name $AcrName --query "passwords[0].value" -o tsv
    
    # Generate unique DNS name
    $dnsLabel = "calculator-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    az container create `
        --resource-group $ResourceGroup `
        --name $AciName `
        --image $acrImage `
        --registry-login-server "${AcrName}.azurecr.io" `
        --registry-username $AcrName `
        --registry-password $acrPassword `
        --ports 8080 `
        --dns-name-label $dnsLabel `
        --cpu 1 `
        --memory 1 `
        --restart-policy Always
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Deployed to Azure Container Instances"
        
        # Get the FQDN
        $fqdn = az container show --resource-group $ResourceGroup --name $AciName --query "ipAddress.fqdn" -o tsv
        Write-Info "Application URL: http://${fqdn}:8080"
        return $true
    }
    else {
        Write-Error "Failed to deploy to Azure Container Instances"
        return $false
    }
}

# Deploy to Azure Kubernetes Service
function Deploy-ToAks {
    $acrImage = "${AcrName}.azurecr.io/${ImageName}:${Version}"
    
    Write-Info "Deploying to Azure Kubernetes Service..."
    
    # Get AKS credentials
    az aks get-credentials --resource-group $ResourceGroup --name $AksCluster --overwrite-existing
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to get AKS credentials"
        return $false
    }
    
    # Update the deployment YAML with the correct image
    $deploymentContent = Get-Content "k8s\deployment.yaml" -Raw
    $updatedContent = $deploymentContent -replace "calculator-web-app:latest", $acrImage
    $updatedContent | Set-Content "k8s\deployment-temp.yaml"
    
    # Apply the deployment
    kubectl apply -f "k8s\deployment-temp.yaml"
    
    if ($LASTEXITCODE -eq 0) {
        # Wait for deployment to be ready
        kubectl rollout status deployment/calculator-web-app --timeout=300s
        
        # Clean up temp file
        Remove-Item "k8s\deployment-temp.yaml" -ErrorAction SilentlyContinue
        
        Write-Success "Deployed to Azure Kubernetes Service"
        
        # Get the service status
        Write-Info "Waiting for LoadBalancer IP..."
        kubectl get service calculator-web-service
        return $true
    }
    else {
        Remove-Item "k8s\deployment-temp.yaml" -ErrorAction SilentlyContinue
        Write-Error "Failed to deploy to Azure Kubernetes Service"
        return $false
    }
}

# Show usage
function Show-Usage {
    Write-Host @"
Calculator Web App Build and Deploy Script (PowerShell)

Usage: .\deploy.ps1 -Action <action> [parameters]

Actions:
  build           Build Docker image
  test            Build and test Docker image locally
  acr             Build, test, and push to Azure Container Registry
  aci             Build, test, push to ACR, and deploy to Azure Container Instances
  aks             Build, test, push to ACR, and deploy to Azure Kubernetes Service
  all             Run all steps (build, test, ACR, ACI, AKS)
  help            Show this help message

Parameters:
  -AcrName        Azure Container Registry name (required for ACR operations)
  -ResourceGroup  Azure Resource Group (default: calculator-rg)
  -AciName        Azure Container Instance name (default: calculator-aci)
  -AksCluster     Azure Kubernetes Service cluster name (default: calculator-aks)
  -ImageName      Docker image name (default: calculator-web-app)
  -Version        Image version (default: latest)

Environment Variables (alternative to parameters):
  ACR_NAME        Azure Container Registry name
  RESOURCE_GROUP  Azure Resource Group
  ACI_NAME        Azure Container Instance name
  AKS_CLUSTER     Azure Kubernetes Service cluster name

Examples:
  .\deploy.ps1 -Action build
  .\deploy.ps1 -Action acr -AcrName myregistry
  .\deploy.ps1 -Action aci -AcrName myregistry -ResourceGroup myrg
"@
}

# Main script logic
function Main {
    switch ($Action.ToLower()) {
        "build" {
            if (-not (Test-Docker)) { exit 1 }
            if (-not (Build-Image)) { exit 1 }
        }
        "test" {
            if (-not (Test-Docker)) { exit 1 }
            if (-not (Build-Image)) { exit 1 }
            if (-not (Test-Image)) { exit 1 }
        }
        "acr" {
            if (-not (Test-Docker)) { exit 1 }
            if (-not (Build-Image)) { exit 1 }
            if (-not (Test-Image)) { exit 1 }
            if (-not (Push-ToAcr)) { exit 1 }
        }
        "aci" {
            if (-not (Test-Docker)) { exit 1 }
            if (-not (Build-Image)) { exit 1 }
            if (-not (Test-Image)) { exit 1 }
            if (-not (Push-ToAcr)) { exit 1 }
            if (-not (Deploy-ToAci)) { exit 1 }
        }
        "aks" {
            if (-not (Test-Docker)) { exit 1 }
            if (-not (Build-Image)) { exit 1 }
            if (-not (Test-Image)) { exit 1 }
            if (-not (Push-ToAcr)) { exit 1 }
            if (-not (Deploy-ToAks)) { exit 1 }
        }
        "all" {
            if (-not (Test-Docker)) { exit 1 }
            if (-not (Build-Image)) { exit 1 }
            if (-not (Test-Image)) { exit 1 }
            if (-not (Push-ToAcr)) { exit 1 }
            if (-not (Deploy-ToAci)) { exit 1 }
            if (-not (Deploy-ToAks)) { exit 1 }
        }
        default {
            Show-Usage
        }
    }
}

# Run the main function
Main