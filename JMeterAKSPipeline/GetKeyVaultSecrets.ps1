[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)]
    [string]$KeyVaultName, 

    [Parameter(Mandatory = $True)]
    [string[]]$SecretNames
)

Write-Host 'fetching secrets from the keyvault...'
try {
    foreach ($secretName in $SecretNames) {
        $secretValue = az keyvault secret show --name $secretName --vault-name $KeyVaultName 
        Write-Host "##vso[task.setvariable variable=$secretName]$secretValue"
    }
    Write-Host 'Secrets have been fetched successfully.'
}
catch {
    Write-Error 'Script failed while fetching the secrets, please validate and try again...'
}


