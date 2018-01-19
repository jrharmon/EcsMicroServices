Param(
  [string]$clusterName, #includes any environment designation (ex. ServiceCluster-DEV)
  [string]$profile,
  [string]$region
)

Function Write-Header ($text)
{
    Write-Host
    Write-Host
    Write-Host
    Write-Host "/*"
    Write-Host "* $text"
    Write-Host "*/"
}

#read in default variables
. $PSScriptRoot\Initialize-DefaultVariables.ps1




#########################################################################################################
#
# Setup common variables (These should be updated to be dynamic)
#
#

if (!$profile) { $profile = $defaultProfile }
if (!$region) { $region = $defaultRegion }






#########################################################################################################
#
# Delete a CloudFormation stack for a cluster
#
#

Write-Header 'Deleting cluster stack'
aws cloudformation delete-stack `
    --stack-name $clusterName `
    --profile $profile `
    --region $region
