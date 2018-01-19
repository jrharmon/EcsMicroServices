# {SERVICE}

[Description needed for this service]

## Development Environment

This service is a .NET Core service, running in Docker on Linux.

### Pre-requisistes

- .NET Core (Installed with Visual Studio 2017)
- Docker
  - Optional, as you can develop locally without it, and let Jenkins handle creating the container after merging your code
  - [Local Installation](deploymentarchitecture.md)

### Running locally

Code can be run locally either directly through the dotnet CLI, or from within a Docker container, giving a more accurate representation of the run-time environment.

## Deployment

Deployments are kicked off by Jenkins when mergin to master in Stash, but can be kick off manually if needed, using Invoke-Deployment.ps1 in the scripts folder.

## Architecture

