# Deployment Architecture

Services are run in Docker containers, running Linux, and hosted in ECS.

## Docker
Docker is the industry standard way to work with containers.  It was originally a Linux only technology, but it now available on Windows, both as a host and (more recently) a client.
We use Linux as the host OS, as it gives us better flexibility for deployments, and is currently much better supported everywhere.

Docker images are built from the Dockerfile script, copying the pre-built service code, and specifying the port to use.  When developing locally, you can use Dockerfile.dev,
which builds and runs the service within the container locally, so that you can test in a more prod-like environment.

#### Docker Local Installation
The more modern Docker for Windows is only supported on Windows 10, as it relies on Hyper-V.  For Windows 7 users, ther is Docker Toolbox, which works just as well, but uses Virtual Box
You can install [Docker](https://www.docker.com/products/docker-toolbox) and [Virtual Box](https://www.virtualbox.org/wiki/Downloads) manually, and then you can just run the following
commands in a PowerShell prompt to get fully setup.

**One Time**
docker-machine create mydock -d virtualbox     //create a vm with docker on it, and start it
docker-machine start mydock                    //start docker machine on the VM

**Each PowerShell Session**
docker-machine env mydock | Invoke-Expression  //setup ENV variables to use the vm for all docker commands

**On Windows Startup**
"C:\Program Files\Oracle\VirtualBox\VBoxManage" startvm "mydock" --type headless //re-start the vm

## ECS
While a little confusing at first, ECS is actually fairly straightforward, once you understand how the various pieces of it interact with themselves, and with the load balancer.

### ECR
This is where the Docker images are uploaded.  Each repository represents a single service, and each image is broken out by their tag.  When referencing an image, you combine the repository url,
the service name, and (optionally) the tag.  If the tag is not specified, the 'latest' tag will be used.

While the 'latest' tag should always point to the most recent image, you should always reference a specific tag, so that you always know which version you are using.

### Application Load Balancer (ALB)
While part of EC2, and not ECS, it interacts closely with ECS to manage dynamic access to containers.  Unlike a normal load balancer (ELB), an ALB isn't tied to a specific destination/port for all requests.
Based on either the path or the host name (we use the host name), it can send to any number of "Target Groups".
A Target Group is something that individual targets (in our case, our service) register with, and traffic is then spread out between them.

A single Target Group is created per service.

### Task Definition
A Task Definition describes what combination of containers are needed to fulfill some purpose.  You specify the Docker images to use, how many containers per image, CPU/memory resources per container, port mappings,
IAM role, and any linkage between containers.  We tend to map task definitions 1-to-1 with a container/image, but having multiple might be useful if your container has dependencies you want to bundle with it, such
as having a Redis container along with every service container.

A single task definition is created per service, and then new revisions are created for any changes, such as pointing to a newer image.  A task can be run directly, but is generally not.

### Service
["Service" with a capital S referse the the ECS Service, and "service" with a lower-case s referse to the service we built, and are deploying]
A Service is built to manage the running of a task, ensuring that the desired number of tasks are running (and spread across EC2s/AZs), handling deployments to newer task revisions, and hooking into a load balancer.
You specify the Target Group to register with (which the ALB is pointing to), and the Service will handle registering each container with it automatically.
When the task definition is setup with a host port of 0, it will make sure that the correct port is registered with the ALB, so that you can have multiple instances of the same service
(running on the same port inside their containers) running on a single EC2 instance.

A service is tied 1-to-1 with a Task.

### Cluster
A cluster is a group of "physical" EC2 instances that have an ECS agent on them that allows them to work together to spread containers between them.  A cluster can have multiple services within it.