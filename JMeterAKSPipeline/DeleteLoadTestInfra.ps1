param(
    [Parameter(Mandatory = $true)]
    [string]$aksClusterName,
    [Parameter(Mandatory = $true)]
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

function log([string] $message) {
    Write-Output "$(get-date) $message"    
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
}
catch {
    Write-Error "An error occurred while deleting Load Test Infra"
    Write-Host $_.ScriptStackTrace
}