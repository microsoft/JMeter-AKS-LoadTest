param(
    [Parameter(Mandatory = $True)]
    [string]$namespace,
    [Parameter(Mandatory = $False)]
    [int]$agentCount = 1
)

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

function log([string] $message, [string] $color) {
    Write-Host "$(get-date) $message" -ForegroundColor $color
    Write-Host " "
}

try {
    $PathToManifestFolder = Join-Path -Path (Split-Path $(Get-Location) -Parent) -ChildPath "jmeter-kubernetes-setup"
    
    #################### Creating JMeter Master and Slave pods ################################################
    log "############## Creating JMeter Slave ##############" "DarkYellow"
    kubectl -n $namespace apply -f $(Join-Path -Path $PathToManifestFolder -ChildPath "jmeter_slaves_deploy.yaml")
    kubectl -n $namespace apply -f $(Join-Path -Path $PathToManifestFolder -ChildPath "jmeter_slaves_svc.yaml")
    log "############## JMeter Slave deployment completed ##############" "DarkGreen"

    log "############## Creating JMeter Master ##############" "DarkYellow"
    kubectl -n $namespace apply -f $(Join-Path -Path $PathToManifestFolder -ChildPath "jmeter_master_configmap.yaml")
    kubectl -n $namespace apply -f $(Join-Path -Path $PathToManifestFolder -ChildPath "jmeter_master_deploy.yaml")
    log "############## JMeter Master deployment completed ##############" "DarkGreen"

    if ($agentCount -gt 1) {
        log "############## Creating $agentCount replicas of JMeter Slave  ##############" "DarkYellow"
        kubectl scale -n $namespace --replicas=$agentCount deployment/jmeter-slaves
    }

    log "############## Total number of Slave pods running the tests $agentCount  ##############" "DarkYellow"

    kubectl -n $namespace rollout status deployment jmeter-master
    kubectl -n $namespace rollout status deployment jmeter-slaves
}
catch {
    Write-Error "An error occurred while creating JMeter cluster"
    Write-Host $_.ScriptStackTrace
}