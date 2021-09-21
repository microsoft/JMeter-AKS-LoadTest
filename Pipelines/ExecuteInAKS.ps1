[CmdletBinding()]
param(
    [Parameter(Mandatory=$True)]
	[string]$AKSClusterName,
	[Parameter(Mandatory=$True)]
	[string]$ResourceGroup,
	[Parameter(Mandatory=$True)]
	[string]$SPNClientId,
	[Parameter(Mandatory=$True)]
	[string]$SPNClientSecret,
	[Parameter(Mandatory=$True)]
	[string]$TenantId,
	[Parameter(Mandatory=$True)]
	[string]$Namespace,
    	[Parameter(Mandatory=$True)]
	[string]$JMeterFolderPath,
    	[Parameter(Mandatory=$True)]
	[string]$JMeterFileName,
    	[string]$CSVFileNames 
)


$AKSClusterNames = New-Object Collections.Generic.List[String]

$AKSClusterNames.Add($AKSClusterName);

$ResourceGroups = New-Object Collections.Generic.List[String]

$ResourceGroups.Add($ResourceGroup);

$ClientIds = New-Object Collections.Generic.List[String]

$ClientIds.Add($SPNClientId);

$ClientSecrets = New-Object Collections.Generic.List[String]

$ClientSecrets.Add($SPNClientSecret);

for ($counter=0; $counter -lt $AKSClusterNames.Count; $counter++){

    az login --service-principal   --username  $ClientIds[$counter]  --password $ClientSecrets[$counter]   --tenant $TenantId

    az aks get-credentials --resource-group $ResourceGroups[$counter] --name $AKSClusterNames[$counter] --overwrite --admin
}

 $AKSClusterNames | ForEach-Object { 


    $currentcontext = $_ + "-admin"

    $rootDirectory = Get-Location

    cd "jmeter-kubernetes-setup"

    kubectl create namespace $Namespace --context $currentcontext

    kubectl create -n $Namespace -f jmeter_slaves_deploy.yaml --context $currentcontext

    kubectl create -n $Namespace -f jmeter_slaves_svc.yaml --context $currentcontext
    
    kubectl create -n $namespace -f jmeter_master_configmap.yaml --context $currentcontext

    kubectl create -n $Namespace -f jmeter_master_deploy.yaml --context $currentcontext

    kubectl get -n $Namespace all --context $currentcontext

    $masternode = kubectl get pods -n $Namespace -o name --context $currentcontext | findstr jmeter-master

    $slaves =  kubectl get pods -n $Namespace -o name --context $currentcontext | findstr jmeter-slaves

    $masternode = $masternode.Substring(4)

    cd $rootDirectory

    cd $JMeterFolderPath

    kubectl cp $JMeterFileName -n $Namespace "${masternode}:/" --context $currentcontext

    $CSVFileNamesList = $CSVFileNames -split ","

    foreach ($slave in $slaves) { 
        $slave = $slave.Substring(4)
        foreach ($CSVFileName in $CSVFileNamesList){
            kubectl cp $CSVFileName -n $Namespace  ${slave}:/ --context $currentcontext
        }
    }

    kubectl get namespace --context $currentcontext

    kubectl exec -ti -n $Namespace $masternode --context $currentcontext -- /bin/bash /load_test $JMeterFileName
    
    New-Item $AKSClusterName  -ItemType "directory"

    kubectl cp $Namespace/${masternode}:report/ $AKSClusterName --context $currentcontext

    kubectl delete namespace $Namespace --context $currentcontext

  }
