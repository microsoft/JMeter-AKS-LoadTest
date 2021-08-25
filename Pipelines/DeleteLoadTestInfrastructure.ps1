param(
    [Parameter(Mandatory = $True)]
    [string]$aksClusterName,
    [Parameter(Mandatory = $True)]
    [string]$resourceGroup,
    [Parameter(Mandatory = $True)]
    [string]$spnClientId,
    [Parameter(Mandatory = $True)]
    [string]$spnClientSecret,
    [Parameter(Mandatory = $True)]
    [string]$tenant
)

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

function log([string] $message, [string] $color) {
    Write-Host "$(get-date) $message" -ForegroundColor $color
    Write-Host " "
}

try {
    if ($(az account list).contains("[]")) {
        Exit-PSSession
    }

    az login --service-principal --username $spnClientId --password $spnClientSecret --tenant $tenant
    
    log "########### Deleting AKS Instance ###########" "DarkYellow"
    az aks delete --name $aksClusterName --resource-group $resourceGroup -y
    log "############# AKS Instance deleted ###############" "DarkGreen"

    log "########### Removing local auth ###########" "DarkYellow"
    kubectl config use-context docker-desktop
    kubectl config delete-context $aksClusterName
    kubectl config delete-cluster $aksClusterName
    kubectl config unset "users.clusterUser_$($aksClusterName)_$($aksClusterName)"
    log "AKS cluster $aksClusterName deleted successfully." "GREEN"   
}
catch {
    Write-Error "An error occurred while deleting Load Test Infrastructure"
    Write-Host $_.ScriptStackTrace
}