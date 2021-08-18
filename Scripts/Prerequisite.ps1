param(
    [Parameter(Mandatory = $true)]
    [string]$subscriptionId,
    [Parameter(Mandatory = $true)]
    [string]$resourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]$kvName,
    [Parameter(Mandatory = $true)]
    [string]$location,
    [Parameter(Mandatory = $true)]
    [string]$certName,
    [Parameter(Mandatory = $true)]
    [string]$kvSecretName,
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
      az login --use-device-code
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
      Write-Warning "You don't have access to required resource group: $resourceGroupName. please elevate your roles via PIM and try again."
      exit
  }
  Write-Host "Pre-requisites check has completed." -ForegroundColor Green
  
  $isKVAvailable  = $(az keyvault list --query "[?name=='$kvName'] | length(@)"  -g $resourceGroupName)
  if($isKVAvailable -eq 1)
  {
    Write-Host "keyvault: $kvName already available ..." -ForegroundColor Green
  }
  else
  {
    Write-Host "Creating keyvault: $kvName ..." -ForegroundColor Green
    az keyvault create --name $kvName --resource-group $resourceGroupName --location $location
  }

  Write-Host "Creating selfsigned certificate in keyvault ..." -ForegroundColor Green
  az keyvault certificate get-default-policy | Out-File -Encoding utf8 defaultpolicy.json
  az keyvault certificate create --vault-name $kvName -n $certName  --policy `@defaultpolicy.json
  az keyvault certificate download --vault-name $kvName -n $certName -f cert.pem

  Write-Host "Creating ServicePrincipal with Password based auth..." -ForegroundColor Green
  $spnResult = az ad sp create-for-rbac -n $servicePrincipalName  --skip-assignment
  $spnDetail = $spnResult | ConvertFrom-Json
  Write-Host "Importing certificate from keyvault to ServicePrincipal ..." -ForegroundColor Green
  az ad sp credential reset -n $servicePrincipalName   --keyvault $kvName --cert $certName --append
   
  Write-Host "Adding ServicePrincipal client secret to keyvault: $kvName ..." -ForegroundColor Green
  az keyvault secret set --vault-name $kvName --name $kvSecretName --value $spnDetail.password
  $spId = az ad sp list --display-name $servicePrincipalName --query [0].appId

  Write-Host "Creating ServiceConnection..." -ForegroundColor Green
  az devops service-endpoint azurerm create --azure-rm-service-principal-id  $spId  --azure-rm-subscription-id  $subscriptionId  --azure-rm-subscription-name  $subscriptionName   --azure-rm-tenant-id  $tenantId  --name $serviceConnectionName  --detect true  --azure-rm-service-principal-certificate-path  'cert.pem'  --org $organizationName  -p $projectName

  Remove-Item cert.pem
  Write-Host "Pre-requisites setup done." -ForegroundColor Green
}
catch {
    Write-Host "Script failed due to some issues, please retry again." -ForegroundColor Red
}