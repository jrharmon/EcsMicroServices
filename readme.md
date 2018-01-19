# AWS ECS Service Infrastructure

## Purpose

This provides scripts and templates that make it easy to quickly create and manage many services within AWS' ECS.

## Pre-Requisites

Pre-requisites were kept to a minimum, but having a few allowed for more efficient service creation.

* Copy Initialize-DefaultVariables.template.ps1 from the root folder, into the scripts folder (removing '.template'), and update the settings within
  * This allows you to customize your settings, without them being merged into Git
    * If you fork the repo, and want your settings stored in Git, simply remove scripts/Initialize-DefaultVariables.ps1 from .gitignore
    * You can even remove the .template version, as it is not referenced anywhere
* Create an EC2 key pair, and store the .pem file securely
  * This is used when creating clusters to allow logging onto the EC2 instances if needed
  * You must have one for each region that you are creating clusters in
  * Update $defaultClusterKeyPair in /scripts/Initialize-DefaultVariables.ps1
* Create an ECS service role
  * Each ECS service needs to run as a role, which is used for creating/killing tasks
  * This is not what the actual Task containers run by the service run as, so you can safely share it across services
  * In the AWS Console, you would create the "AWS Service Role -> Amazon EC2 Container Service Role" role type
    * This adds the arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole policy and adds ecs.amazonaws.com as a trusted entity
    * You must set $defaultEcsServiceRole in /scripts/Initialize-DefaultVariables.ps1 to the name of the role created
      * Default is ecsServiceRole
* Route53 must be setup, allowing you to create sub-host names for each service.  The host name is what the ALB will use to direct all requests
  to the correct service.
  * Update $defaultRootServiceHostName in /scripts/Initialize-DefaultVariables.ps1 to the hosted zone being used
* Docker must be setup on your computer and running

## Features

In the root 'scripts' folder, are PowerShell scripts that perform the major functions of service management.

### Create ECS Cluster

Create a new ECS cluster in its own VPC.  Also include an Application Load Balancer (ALB), which will be used by all services.
The ALB will check the host name of each request to determine which service to send it to.

### Create Service

## Service Templates

Services are created from templates under /resources/templates.  You can add any additional templates you want, for any type of service (.Net Core, Node, Go, etc.).
To create a template, simply create a normal service, and use the text 'TemplateNameToken' anywhere that you want the name replaced with the final service name.
By not having any special designation for the replacement token, you can actually build the template app directly, making it easier to edit.  It also makes it easier to name files.

Feature options are not currently supported, but may come later.

## Naming Standards

## Design Goals

* Flat architecture as much as possible.  Just a bunch of scripts that have as few dependencies as possible