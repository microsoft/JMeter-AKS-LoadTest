param(
    [Parameter(Mandatory = $True)]
    [string]$tenant,
    [Parameter(Mandatory = $True)]
    [string]$defaultNamespace,
    [Parameter(Mandatory = $True)]
    [string]$resourceGroup,
    [Parameter(Mandatory = $True)]
    [string]$aksClusterName,
    [Parameter(Mandatory = $True)]
    [string]$spnClientId,
    [Parameter(Mandatory = $True)]
    [string]$spnClientSecret,
    [Parameter(Mandatory = $True)]
    [string]$aksRegion,
    [Parameter(Mandatory = $False)]
    [string]$nodeVmSize = "Standard_D2s_v3"
)

function log([string] $message, [string] $color) {
    Write-Host "$(get-date) $message" -ForegroundColor $color
    Write-Host " "
}

#################### Creating AKS Cluster ################################################

try {
    log "############# Installing Extension : aks-preview ###############" "DarkYellow"
    az extension add --name aks-preview
    
    az login --service-principal --username $spnClientId --password $spnClientSecret --tenant $tenant
    
    log "############# AKS Cluster Name : $($aksClusterName) ###############" "DarkMagenta"
    log "############# Creating AKS Cluster ###############" "DarkYellow"
    az aks create --resource-group $resourceGroup --name $aksClusterName --node-vm-size $nodeVmSize --location $aksRegion --service-principal $spnClientId --client-secret $spnClientSecret --node-count 3  --min-count 1 --max-count 50 --enable-cluster-autoscaler --enable-aad --enable-azure-rbac --generate-ssh-keys
    log "############# AKS Cluster creation completed ###############" "DarkGreen"
    
    log "############# Getting cluster credentials #############" "DarkYellow"
    az aks get-credentials --name $aksClusterName --resource-group $resourceGroup --admin
    
    log "############# Creating AKS Namespace #############" "DarkYellow"
    kubectl create namespace $defaultNamespace
    log "AKS cluster $aksClusterName created successfully." "GREEN"   
}
catch {
    Write-Error "An error occurred while creating Load Test Infrastructure"
    Write-Host $_.ScriptStackTrace
}