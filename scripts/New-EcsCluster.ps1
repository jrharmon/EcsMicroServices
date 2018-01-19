Param(
  [string]$clusterName, #includes any environment designation (ex. ServiceCluster-DEV)
  [string]$instanceType,
  [string]$clusterSize = 1,
  [string]$keyPair,
  [string]$managementCidr,
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
# Setup common variables
#
#

if (!$instanceType) { $instanceType = $defaultClusterInstanceType }
if (!$keyPair) { $keyPair = $defaultClusterKeyPair }
if (!$managementCidr) { $managementCidr = $defaultManagementCidr }
if (!$profile) { $profile = $defaultProfile }
if (!$region) { $region = $defaultRegion }





#########################################################################################################
#
# Create a CloudFormation stack for a cluster
#
#

Write-Header 'Creating cluster stack'
aws cloudformation create-stack `
    --stack-name $clusterName `
    --template-body "file://$PSScriptRoot\..\resources\cloudformation\ecs-cluster.yaml" `
    --capabilities CAPABILITY_NAMED_IAM `
    --parameters `
      ParameterKey=InstanceType,ParameterValue=$instanceType `
      ParameterKey=ClusterSize,ParameterValue=$clusterSize `
      ParameterKey=KeyName,ParameterValue=$keyPair `
      ParameterKey=ManagementCidr,ParameterValue=$managementCidr `
    --profile $profile `
    --region $region
