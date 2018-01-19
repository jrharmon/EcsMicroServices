# This is a temporary script use to help with rapid testing
# if a TST environment exists, just delete its CF stack manually first (just the R53 entry will be left, which is fine for now)

Param(
  [string]$serviceName,
  [string]$environment = "DEV",
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

[Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath






#########################################################################################################
#
# Setup common variables
#
#

if (!$profile) { $profile = $defaultProfile }
if (!$region) { $region = $defaultRegion }






#########################################################################################################
#
# Delete resources
#
#

Write-Header 'Deleting service stack'
aws cloudformation delete-stack --stack-name "$($serviceName)-$environment" --profile $profile --region $region


Write-Header 'Delete Stash repo'
$passwordSecure = Read-host -Prompt "Stash password" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSecure))
$pair = "$($env:UserName):$($password)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{ Authorization = $basicAuthValue }
Invoke-WebRequest -Uri "https://$($bitBucketHostName)/rest/api/1.0/projects/~$($env:UserName)/repos/$serviceName" -Method Delete -Headers $Headers


Write-Header 'Delete service folder'
[Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath
rmdir -Recurse -Force $serviceName


Write-Header 'Delete ECR repo'
aws ecr get-login --profile $profile --region $region | Invoke-Expression
aws ecr delete-repository --repository-name $serviceName --force --profile $profile --region $region




#TODO: delete route 53 entry



exit 0



Write-Header 'Delete task definitions'
Do {
    $tdJson = aws ecs describe-task-definition --task-definition $serviceName --profile $profile --region $region
    $taskDefinition = (($tdJson) -Join " ") | ConvertFrom-Json #json needs to be a single string, instead of a list
    $taskDefinitionRevision = $taskDefinition.taskDefinition.revision
    Write-Host "Task Definition Revision:" $taskDefinitionRevision
    aws ecs deregister-task-definition --task-definition "$($serviceName):$($taskDefinitionRevision)" --profile $profile --region $region
} While ($taskDefinitionRevision -ne $NULL)
Write-Host "Ignore any error about invalid revision number, or being unable to describe a task definition."
Write-Host "Everything deleted fine."

