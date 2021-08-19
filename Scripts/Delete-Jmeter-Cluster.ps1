param(
    [Parameter(Mandatory = $true)]
    [string]$namespace
)

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

try {
    $PathToManifestFolder = Join-Path -Path (Split-Path $(Get-Location) -Parent) -ChildPath "jmeter-kubernetes-setup"
    
    log "############## Removing JMeter Master and Slave pods ##############" "DarkYellow"
    kubectl -n $namespace delete -f $(Join-Path -Path $PathToManifestFolder -ChildPath "jmeter_master_deploy.yaml") --wait=true
    kubectl -n $namespace delete -f $(Join-Path -Path $PathToManifestFolder -ChildPath "jmeter_slaves_deploy.yaml") --wait=true
    kubectl -n $namespace wait --for=delete pods --selector=jmeter_mode=master --timeout=60s
    kubectl -n $namespace wait --for=delete pods --selector=jmeter_mode=slave --timeout=60s
}
catch {
    Write-Error "An error occurred while deleting JMeter cluster"
    Write-Host $_.ScriptStackTrace
}