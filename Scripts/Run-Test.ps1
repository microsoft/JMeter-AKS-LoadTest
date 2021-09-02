param(
    [Parameter(Mandatory = $False)]
    [string]$namespace = "",
    [Parameter(Mandatory = $True)]
    [string]$aksClusterName,
    [Parameter(Mandatory = $True)]
    [string]$resourceGroup,
    # Complete path of test
    [Parameter(Mandatory = $True)]
    [string]$testPath,
    # Relative Path to Script Folder
    [Parameter(Mandatory = $False)]
    [string]$reportFolder = "Reports",
    # Add more than 1 instances
    [Parameter(Mandatory = $False)]
    [int]$agentCount = 1,
    [Parameter(Mandatory = $False)]
    [bool]$deleteJMeterCluster = $True,
    [Parameter(HelpMessage = "Change this to true if you want to keep the namespace intact. Otherwise the namespace will be deleted after the test")]
    [bool]$retainNamespace = $False
)

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

function log([string] $message, [string] $color) {
    Write-Host "$(get-date) $message" -ForegroundColor $color
    Write-Host " "
}

$SlavePods = ''
$folderName = "report_" + (Get-Date).tostring("dd-MM-yyyy-hh-mm-ss") 
$root = $PSScriptRoot
try {
    log "############## Test Execution Started ##############" "DarkCyan" 
    log "############## Getting Cluster Credentials ##############" "DarkCyan"
    az aks get-credentials --name $aksClusterName --resource-group $resourceGroup --admin

    if ($namespace -eq '') {
        log "############## Namespace not specified so creating new namespace ##############" "DarkCyan" 
        $chars = [char[]]"abcdefghijklmnopqrstuvwxyz0123456789"
        $randomString = [string](($chars | Get-Random -Count 5) -join "")
        $namespace = 'jmeter' + "-" + $randomString
        kubectl create namespace $namespace
        log "############## Created Namespace - $($namespace)  ##############" "DarkCyan" 
    }

    $IsEligibleUser = $(kubectl auth can-i create deployments --namespace $namespace)

    if ($IsEligibleUser -ne 'yes') {
        Write-Error "############## Cannot Continue Test Execution, get contributor access on cluster ##############"
        exit
    }

    Invoke-Expression "& '$root\Create-Jmeter-Cluster.ps1' -namespace $namespace -agentCount $agentCount"

    if ($null -eq $(kubectl -n $namespace get pods --selector=jmeter_mode=master --no-headers=true --output=name) ) {
        Write-Error "Master pod does not exist"
        exit
    }
    
    $MasterPod = $(kubectl -n $namespace get pods --selector=jmeter_mode=master --no-headers=true --output=name).Replace("pod/", "")
    $TestName = Split-Path $testPath -Leaf
    log "############## Copying test plan $TestName to controller pod ##############" "DarkYellow"
    kubectl cp $testPath $namespace/${MasterPod}:/$TestName

    $SlavePods = $(kubectl -n $namespace get pods --selector=jmeter_mode=slave --no-headers=true --output=name)
    $SlavePod = ""

    log "############## Executing test ##############" "DarkYellow"
    kubectl -n $namespace exec $MasterPod -- /bin/bash /load_test "$TestName"
    
    log "############## Retrieving dashboard and results to : $($root  + '\' + $reportFolder + '\' + $folderName) ##############"  "Green"
    kubectl cp $namespace/${MasterPod}:/report $reportFolder/$folderName

    foreach ($SlavePod in $SlavePods) {
        $SlavePod = $SlavePod -replace 'pod/', ''
        kubectl cp -n $namespace ${SlavePod}:jmeter-server.log $reportFolder/$folderName/jmeter-server-$SlavePod.log
    }
}
catch {
    Write-Error "An error occurred while running Load Test"
    Write-Host $_.ScriptStackTrace
}

finally {
    if ($deleteJMeterCluster) {
        Invoke-Expression "& '$root\Delete-Jmeter-Cluster.ps1' -namespace $namespace"
    }
    
    if (!($retainNamespace)) {
        log "############## Deleting namespace $namespace ##############" "DarkCyan"
        kubectl delete namespace $namespace
    }
    log "############## Test Execution Ends ##############" "DarkCyan"
}