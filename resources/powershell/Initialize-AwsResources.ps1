# Add all necessary AWS resources for the service.  This should only need to be run at service creation, or when moving to a new region/account
# requires aws cli version 1.11, for elbv2 commands

Param(
  [string]$clusterName = "{CLUSTER}",
  [string]$environment = "DEV",
  [string]$createEcrRepository = $FALSE,
  [string]$profile = "{PROFILE}",
  [string]$route53Profile = "admin",
  [string]$region = "{REGION}"
)

#set current directory to the real directory, and not the home directory (this can keep [System.IO.Path]::GetFullPath(".") from giving the wrong value)
[Environment]::CurrentDirectory=$PSScriptRoot
Write-Host $([Environment]::CurrentDirectory)

#print a large header to the console to make it easier to read the logs
Function Write-Header ($text)
{
    Write-Host
    Write-Host
    Write-Host
    Write-Host "/*"
    Write-Host "* $text"
    Write-Host "*/"
}





#########################################################################################################
#
# Setup common variables
#
#

$serviceName = "{SERVICE}"
$initialContainerTag = "0.1.0"
$ecsServiceRole = "{ECSSERVICEROLE}"
$rootHostName = "{ROOTHOSTNAME}" # services will get a url of $servicename.$rootHostName
if ($dnsPrefix -eq "PRD") { $dnsPrefix = "" }
else { $dnsPrefix = $environment.ToLower() + "." }
Write-Host $dnsPrefix


#get dynamic values from AWS
$accountId = (aws sts get-caller-identity --profile $profile --query 'Account' --output text)
$albDns = (aws cloudformation list-exports --profile $profile --region $region --query "Exports[?Name==``$($clusterName)-$($environment)-AlbDns``].Value" --output text)
$albListenerArn = (aws cloudformation list-exports --profile $profile --region $region --query "Exports[?Name==``$($clusterName)-$($environment)-AlbListenerArn``].Value" --output text)
$r53ZoneId = (aws route53 list-hosted-zones --profile $route53Profile --query "HostedZones[?Name==``$($rootHostName).``].Id" --output text)

Write-Host $accountId
Write-Host $albDns
Write-Host $albListenerArn
Write-Host $r53ZoneId





#########################################################################################################
#
# Determine next available ALB listener rule priority
#
#

#determine the next available rule priority for the ALB listener
Write-Header 'Determining next rule number for ALB listener'
$lrJson = aws elbv2 describe-rules --listener-arn $albListenerArn --profile $profile --region $region
$listenerRules = (($lrJson) -Join " ") | ConvertFrom-Json #json needs to be a single string, instead of a list
$maxPriority = 0
ForEach ($rule in $listenerRules.Rules) {
  if ($rule.Priority -ne "default" -and $rule.Priority -gt $maxPriority) {
    $maxPriority = $rule.Priority
  }
}
$listenerRuleNumber = ([int]$maxPriority + 10)
Write-Host "Listener rule #:" $listenerRuleNumber





#########################################################################################################
#
# Setup Docker image and repository (ECR), and push the image
#
#

#build the release docker image and tag it
Write-Header 'Creating docker image'
dotnet publish -c Release -o out
docker build -t $serviceName $PSScriptRoot\..\..
docker tag $serviceName "$accountId.dkr.ecr.$($region).amazonaws.com/$($serviceName):latest"
docker tag $serviceName "$accountId.dkr.ecr.$($region).amazonaws.com/$($serviceName):$($initialContainerTag)"
docker images

#push the image (creating the repo first if needed)
Write-Header 'Pushing docker image to ECR'
aws ecr get-login --profile $profile --region $region | Invoke-Expression
if ($createEcrRepository -eq $TRUE) {
  aws ecr create-repository --repository-name $serviceName --profile $profile --region $region
}
docker push "$accountId.dkr.ecr.$($region).amazonaws.com/$($serviceName)" #by not listing a tag, all tags are pushed
cls #pushing seems to screw up the screen, so clear it afterwards






#########################################################################################################
#
# Create a CloudFormation stack for the service
#
#

Write-Header 'Creating service stack'
aws cloudformation create-stack `
    --stack-name "$($serviceName)-$environment" `
    --template-body "file://$PSScriptRoot\..\..\service-definition.yaml" `
    --capabilities CAPABILITY_NAMED_IAM `
    --parameters `
      ParameterKey=ServiceName,ParameterValue=$serviceName `
      ParameterKey=ClusterStackName,ParameterValue=$($clusterName)-$environment `
      ParameterKey=ContainerImageTag,ParameterValue=$initialContainerTag `
      ParameterKey=EcsServiceRole,ParameterValue=$ecsServiceRole `
      ParameterKey=ListenerRulePriority,ParameterValue=$listenerRuleNumber `
      ParameterKey=ListenerRuleHostName,ParameterValue=$dnsPrefix$servicename.$rootHostName `
    --profile $profile `
    --region $region





#########################################################################################################
#
# Setup Route 53
#
#

#create route 53 entry for $dnsPrefix$servicename.$rootHostName (needs to be run as someone who has permission to create route 53 record sets)
#this is outside of the CF template, as Route53 is often in a different account than the service
Write-Header 'Creating Route 53 entry'
$r53Json =  "{
  \""ChangeBatch\"": {
    \""Comment\"": \""Add the DNS entry for {SERVICE} in PRD\"",
    \""Changes\"": [{
      \""Action\"": \""UPSERT\"",
      \""ResourceRecordSet\"": {
        \""Name\"": \""$dnsPrefix$servicename.$rootHostName.\"",
        \""Type\"": \""CNAME\"",
        \""TTL\"": 300,
        \""ResourceRecords\"": [{ \""Value\"": \""$albDns\"" }]
      }
    }]
  }
}".Replace("`r`n", "")
aws route53 change-resource-record-sets --hosted-zone-id $r53ZoneId --cli-input-json "$r53Json" --profile $route53Profile #(route53 is global) --region $region