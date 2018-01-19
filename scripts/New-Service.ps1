Param(
  [string]$serviceName, #does not include the environment in the name
  [string]$clusterName, #the initial cluster to deploy the service to, without the environment designation
  [string]$serviceLocalPort = "5000", #the port to run the service against locally when using Invoke-DevBuild.ps1
  [string]$rootHostName,
  [string]$ecsServiceRole,
  [string]$profile,
  [string]$region
)

#change directory, and set Powershell's current directory to the file system's (if you just cd, regular commands will run from that directory, but not PowerShell ones)
Function Update-PsCurrentDirectory ($directory) {
  cd $directory
  [Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath
}
Update-PsCurrentDirectory(".") #run at the start to make sure the script is configured in the correct starting directory

#import functions
Import-Module $PSScriptRoot\ps_modules\File-Commands.psm1 -force

#read in default variables
. $PSScriptRoot\Initialize-DefaultVariables.ps1



#TODO: fail when errors are thrown






#########################################################################################################
#
# Setup common variables
#
#

if (!$rootHostName) { $rootHostName = $defaultRootServiceHostName }
if (!$ecsServiceRole) { $ecsServiceRole = $defaultEcsServiceRole }
if (!$profile) { $profile = $defaultProfile }
if (!$region) { $region = $defaultRegion }





#########################################################################################################
#
# Setup new service folder with initial template code, and cd into it
#
#

#create the .NET Core app, restore and publish it, so that the docker build will work (it expects a published app in the 'out' folder)
Write-Header 'Creating .NET Core app, and building it'
Copy-Folder $PSSCriptRoot\..\resources\templates\CoreWeb .\$serviceName "TemplateNameToken=$serviceName"
Update-PsCurrentDirectory $serviceName
dotnet restore
dotnet publish -c Release -o out





#########################################################################################################
#
# Add additional files (generic, so not stored within the template folder)
#
#

#create docker files for deployment and development
Write-Header 'Creating docker files'
Copy-File $PSSCriptRoot\..\resources\docker\Dockerfile Dockerfile "{SERVICE}=$serviceName"
Copy-File $PSSCriptRoot\..\resources\docker\Dockerfile.dev Dockerfile.dev "{SERVICE}=$serviceName"
Copy-Item $PSSCriptRoot\..\resources\docker\.dockerignore .dockerignore

#create build/deployment scripts
Write-Header 'Creating build scripts'
Copy-File $PSSCriptRoot\..\resources\powershell\Invoke-Deployment.ps1 scripts\Invoke-Deployment.ps1 "{SERVICE}=$serviceName"
Copy-File $PSSCriptRoot\..\resources\powershell\Invoke-DevBuild.ps1 scripts\Invoke-DevBuild.ps1 "{SERVICE}=$serviceName,{DEVPORT}=$serviceLocalPort"
Copy-File $PSSCriptRoot\..\resources\powershell\Invoke-ReleaseBuild.ps1 scripts\Invoke-ReleaseBuild.ps1 "{SERVICE}=$serviceName"

#create aws initialization script, and supporting files
Write-Header 'Creating AWS initialization script'
Copy-File $PSSCriptRoot\..\resources\powershell\Initialize-AwsResources.ps1 scripts\init\Initialize-AwsResources.ps1 "{SERVICE}=$serviceName,{CLUSTER}=$clusterName,{ROOTHOSTNAME}=$rootHostName,{ECSSERVICEROLE}=$ecsServiceRole,{PROFILE}=$profile,{REGION}=$region"
Copy-File $PSSCriptRoot\..\resources\cloudformation\service.yaml service-definition.yaml "{SERVICE}=$serviceName" $true





#########################################################################################################
#
# Setup Git and Stash
#
#

#setup git
Write-Header 'Configuring Git'
git init
git add --all
git commit -m 'initial commit'

#setup stash repo
Write-Header 'Registering Git repo with Stash'
$passwordSecure = Read-host -Prompt "Stash password" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSecure))
$pair = "$($env:UserName):$($password)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{ Authorization = $basicAuthValue }
$json = '{"name":"' + $serviceName + '", "scmId": "git", "forkable": true}'
Invoke-WebRequest -Uri "https://$($bitBucketHostName)/rest/api/1.0/projects/~$($env:UserName)/repos" -Body $json -ContentType "application/json" -Method Post -Headers $Headers

#push initial commit
Write-Header 'Pushing initial commit'
$remoteUrl = "ssh://git@$($bitBucketHostName):7999/~$($env:UserName)/$serviceName.git"
Write-Host $remoteUrl
git remote add origin $remoteUrl
git push -u origin master




#########################################################################################################
#
# Run the AWS init script
#
#

Write-Header 'Initializing AWS'
.\scripts\init\Initialize-AwsResources.ps1 -createEcrRepository $TRUE



#go back to the initial directory once complete
Update-PsCurrentDirectory ".."
exit 0
