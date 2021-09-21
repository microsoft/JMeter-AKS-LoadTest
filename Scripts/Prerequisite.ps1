param(
    [Parameter(Mandatory = $true)]
    [string]$subscriptionId,
    [Parameter(Mandatory = $true)]
    [string]$resourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]$keyVaultName,
    [Parameter(Mandatory = $true)]
    [string]$location,
    [Parameter(Mandatory = $true)]
    [string]$certName,
    [Parameter(Mandatory = $true)]
    [string]$ServicePrincipalSecret,
    [Parameter(Mandatory = $true)]
    [string]$servicePrincipalName,
    [Parameter(Mandatory = $true)]
    [string]$tenantId,
    [Parameter(Mandatory = $true)]
    [string]$serviceConnectionName,
    [Parameter(Mandatory = $true)]
    [string]$organizationName,
    [Parameter(Mandatory = $true)]
    [string]$projectName
)

try {
  
  $pemCertFile = 'cert.pem'
  $isLoggedIn = az account show 
  if ($null -eq $isLoggedIn) {
      Write-Host "logging In..." -ForegroundColor White
      az login
  }
  
  Write-Host "Initiating pre-requisites validation..." -ForegroundColor White
  $subscriptionName = az account list --query "[?id=='$subscriptionId'].name" -o tsv
  if ($null -eq $subscriptionName) {
      Write-Warning "You don't have access to subcription: $subscriptionId ."
      exit
  }
  else {
      Write-Host "Switching to subscription: $subscriptionId" -ForegroundColor White
      az account set -s $subscriptionId 
  }
    
  $rgAccess = az group show --name $resourceGroupName --query "name" -o tsv    
  if ($null -eq $rgAccess) {
      Write-Warning "You don't have access to resource group: $resourceGroupName."
      exit
  }

  Write-Host "Checking the required extensions ..." -ForegroundColor White
  $extension = 'azure-devops'
  $extensionName = az extension show --name $extension --query "[name]"  -o tsv
  if ($null -eq $extensionName) {
     Write-Host "Installing $extension via azure CLI ..." -ForegroundColor White
     az extension add --name $extension --yes
  }

  Write-Host "Pre-requisites check has completed." -ForegroundColor Green
  Write-Host "Executing pre-requisite setup script." -ForegroundColor White
  
  $isKVAvailable  = $(az keyvault list --query "[?name=='$keyVaultName'] | length(@)"  -g $resourceGroupName)
  if($isKVAvailable -eq 1) {
    Write-Host "keyvault: $keyVaultName already available ..." -ForegroundColor White
  }
  else {
    Write-Host "Creating keyvault: $keyVaultName ..." -ForegroundColor White
    az keyvault create --name $keyVaultName --resource-group $resourceGroupName --location $location
  }

  Write-Host "Creating selfsigned certificate in keyvault ..." -ForegroundColor White
  az keyvault certificate create --vault-name $keyVaultName -n $certName  --policy `@PEMCertCreationPolicy.json
  az keyvault secret download --vault-name $keyVaultName -n $certName -f $pemCertFile

  #Trim Cert file and remove extra lines
  $directoryPath = Get-Location
  $filePath = "$($directoryPath)\$($pemCertFile)"
  $fileContent = [System.IO.File]::OpenText($filePath)
  $text = ($fileContent.readtoend()).trim("`r`n")
  $fileContent.close()  
  $stream = [System.IO.StreamWriter]$filePath
  $stream.write($text)
  $stream.close()

  Write-Host "Creating App registration ..." -ForegroundColor White
  az ad app create --display-name $servicePrincipalName
  $appId = az ad app list --display-name $servicePrincipalName --query [0].appId
  Write-Host "Creating Service Principal ..." -ForegroundColor White
  az ad sp create --id $appId

  Write-Host "Importing certificate from keyvault to ServicePrincipal ..." -ForegroundColor White
  az ad sp credential reset -n $servicePrincipalName --keyvault $keyVaultName --cert $certName --append
   
  Write-Host "Adding ServicePrincipal client secret to keyvault: $keyVaultName ..." -ForegroundColor White
  $spnResult = az ad sp credential reset --name $servicePrincipalName
  $spnDetail = $spnResult | ConvertFrom-Json 
  az keyvault secret set --vault-name $keyVaultName --name $ServicePrincipalSecret --value $spnDetail.password
  $spId = az ad sp list --display-name $servicePrincipalName --query [0].appId

  Write-Host "Adding ServicePrincipal to keyvault access policies ..." -ForegroundColor White
  $objectId = az ad sp show  --id $spId  --query 'objectId'
  az keyvault set-policy --name $keyVaultName --object-id $objectId  --secret-permissions  get list  --key-permissions get list  --certificate-permissions  get list
  Write-Host "Creating ServiceConnection ..." -ForegroundColor White
  az devops service-endpoint azurerm create --azure-rm-service-principal-id  $spId  --azure-rm-subscription-id  $subscriptionId  --azure-rm-subscription-name  $subscriptionName   --azure-rm-tenant-id  $tenantId  --name $serviceConnectionName  --detect true  --azure-rm-service-principal-certificate-path  $pemCertFile  --org $organizationName  -p $projectName

  Remove-Item $pemCertFile
  Write-Host "Pre-requisites setup done." -ForegroundColor Green
}
catch {
    Write-Error "Script failed due to some issues, please retry again." -ForegroundColor Red
}