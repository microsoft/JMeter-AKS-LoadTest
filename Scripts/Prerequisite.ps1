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
    [string]$keyVaultSecretNameForServicePrincipal,
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
  Write-Host "Pre-requisites check has completed." -ForegroundColor Green
  Write-Host "Executing pre-requisite setup script." -ForegroundColor Green
  
  $isKVAvailable  = $(az keyvault list --query "[?name=='$keyVaultName'] | length(@)"  -g $resourceGroupName)
  if($isKVAvailable -eq 1)
  {
    Write-Host "keyvault: $keyVaultName already available ..." -ForegroundColor Green
  }
  else
  {
    Write-Host "Creating keyvault: $keyVaultName ..." -ForegroundColor Green
    az keyvault create --name $keyVaultName --resource-group $resourceGroupName --location $location
  }

  Write-Host "Creating selfsigned certificate in keyvault ..." -ForegroundColor Green
  az keyvault certificate get-default-policy | Out-File -Encoding utf8 defaultpolicy.json
  az keyvault certificate create --vault-name $keyVaultName -n $certName  --policy `@defaultpolicy.json
  az keyvault certificate download --vault-name $keyVaultName -n $certName -f cert.pem

  Write-Host "Creating App registration..." -ForegroundColor Green
  az ad app create --display-name $servicePrincipalName
  $appId = az ad app list --display-name $servicePrincipalName --query [0].appId
  Write-Host "Creating Service Principal..." -ForegroundColor Green
  az ad sp create --id $appId

  Write-Host "Importing certificate from keyvault to ServicePrincipal ..." -ForegroundColor Green
  az ad sp credential reset -n $servicePrincipalName   --keyvault $keyVaultName --cert $certName --append
   
  Write-Host "Adding ServicePrincipal client secret to keyvault: $keyVaultName ..." -ForegroundColor Green
  $spnResult = az ad sp credential reset --name $servicePrincipalName
  $spnDetail = $spnResult | ConvertFrom-Json 
  az keyvault secret set --vault-name $keyVaultName --name $keyVaultSecretNameForServicePrincipal --value $spnDetail.password
  $spId = az ad sp list --display-name $servicePrincipalName --query [0].appId

  Write-Host "Adding ServicePrincipal to keyvault access policies ..." -ForegroundColor Green
  $objectId = az ad app show  --id $spId  --query 'objectId'
  az keyvault set-policy --name $keyVaultName --object-id $objectId  --secret-permissions backup delete get list recover restore set --key-permissions backup create delete get import list recover restore sign update verify   --certificate-permissions  backup create delete deleteissuers get getissuers import list listissuers managecontacts manageissuers recover restore setissuers update

  Write-Host "Creating ServiceConnection ..." -ForegroundColor Green
  az devops service-endpoint azurerm create --azure-rm-service-principal-id  $spId  --azure-rm-subscription-id  $subscriptionId  --azure-rm-subscription-name  $subscriptionName   --azure-rm-tenant-id  $tenantId  --name $serviceConnectionName  --detect true  --azure-rm-service-principal-certificate-path  'cert.pem'  --org $organizationName  -p $projectName

  Remove-Item cert.pem
  Write-Host "Pre-requisites setup done." -ForegroundColor Green
}
catch {
    Write-Error "Script failed due to some issues, please retry again." -ForegroundColor Red
}