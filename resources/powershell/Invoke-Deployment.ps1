Param(
  [string]$environment = "DEV",
  [string]$containerTag = "0.1.1",
  [string]$profile = "{PROFILE}",
  [string]$region = "{REGION}"
)

#import functions
Import-Module $PSScriptRoot\init\File-Commands.psm1 -force


#########################################################################################################
#
# Setup common variables
#
#

$serviceName = "{SERVICE}"
$accountId = (aws sts get-caller-identity --profile $profile --query 'Account' --output text)
$dockerRepo = "$accountId.dkr.ecr.$region.amazonaws.com/$serviceName"



#TODO:
# properly read/parse a version.txt file, and update increment the build number when tagging

#########################################################################################################
#
# Build updated Docker image, and push the image into ECR
#
#

#build the service
Write-Host 'Building the app'
dotnet restore "$PSScriptRoot\.."
dotnet publish "$PSScriptRoot\.." -c Release -o out

#build the release docker image and tag it
Write-Host 'Creating docker image'
docker build -t $serviceName $PSScriptRoot\..
docker tag $serviceName "$($dockerRepo):latest"
docker tag $serviceName "$($dockerRepo):$containerTag"
docker images

#login to ECR, and push the latest container image
Write-Host 'Pushing docker image to ECR'
aws ecr get-login --profile $profile --region $region | Invoke-Expression
docker push "$dockerRepo" #by not listing a tag, all tags are pushed
cls #pushing seems to screw up the screen, so clear it afterwards






#########################################################################################################
#
# Update the CloudFormation stack for the service (normally just updates the tag, but any manual changes to service-definition.yaml will also be applied)
#
#

Write-Header 'Updating service stack'
aws cloudformation update-stack `
    --stack-name "$($serviceName)-$environment" `
    --template-body "file://$PSScriptRoot\..\service-definition.yaml" `
    --capabilities CAPABILITY_NAMED_IAM `
    --parameters `
      ParameterKey=ContainerImageTag,ParameterValue=$containerTag `
      ParameterKey=ServiceName,UsePreviousValue=true `
      ParameterKey=ClusterStackName,UsePreviousValue=true `
      ParameterKey=ListenerRulePriority,UsePreviousValue=true `
      ParameterKey=ListenerRuleHostName,UsePreviousValue=true `
    --profile $profile `
    --region $region