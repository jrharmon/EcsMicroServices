# {SERVICE}

[Description needed for this service]

## Development Environment

This service is a Node service, running in Docker on Linux.

### Pre-requisistes

- Node
- Docker (Optional for pure development)
  - Either Docker for Windows if on Windows 10 or Docker Toolbox for Windows 7

### Running locally

Code can be run locally either directly through the dotnet CLI, or from within a Docker container, giving a more accurate representation of the run-time environment.

## Deployment

Deployments are kicked off by Jenkins when mergin to master in Stash, but can be kick off manually if needed, using Invoke-Deployment.ps1 in the scripts folder.

## Architecture

