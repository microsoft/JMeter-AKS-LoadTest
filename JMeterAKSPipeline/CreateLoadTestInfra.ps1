param(
    [Parameter(Mandatory = $True)]
    [string]$Tenant,
    [Parameter(Mandatory = $True)]
    [string]$DefaultNamespace,
    [Parameter(Mandatory = $True)]
    [string]$ResourceGroup,
    [Parameter(Mandatory = $True)]
    [string]$AksClusterName,
    [Parameter(Mandatory = $True)]
    [string]$SPNClientId,
    [Parameter(Mandatory = $True)]
    [string]$SPNClientSecret,
    [Parameter(Mandatory = $True)]
    [string]$AksRegion,
    [Parameter(Mandatory = $False)]
    [string]$NodeVmSize = "Standard_D2s_v3"
)

function log([string] $message, [string] $color) {
    Write-Host "$(get-date) $message"   -ForegroundColor $color 
    Write-Host " " 
}

#################### Creating AKS Cluster ################################################

log "############# Installing Extension : aks-preview ###############" "DarkYellow"
az extension add --name aks-preview

az login --service-principal --username $SPNClientId --password $SPNClientSecret --tenant $Tenant

log "############# AKS Cluster Name : $($AksClusterName) ###############" "DarkMagenta"
log "############# Creating AKS Cluster ###############" "DarkYellow"
az aks create --resource-group $ResourceGroup --name $AksClusterName --node-vm-size $NodeVmSize --location $AksRegion --service-principal $SPNClientId --client-secret $SPNClientSecret --node-count 3  --min-count 1 --max-count 50 --enable-cluster-autoscaler --enable-aad --enable-azure-rbac --generate-ssh-keys
log "############# AKS Cluster creation completed ###############" "DarkGreen"

log "############# Getting cluster credentials #############"  "DarkYellow"
az aks get-credentials --name $AksClusterName --resource-group $ResourceGroup --admin

log "############# Creating AKS Namespace #############" "DarkYellow"
kubectl create namespace $DefaultNamespace