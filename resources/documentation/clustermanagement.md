# ECS Cluster Management

## Remoting into a container
[AWS Documentation](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/instance-connect.html)

SSHing into a machine in a cluster can be useful for diagnosing issues with a service.  To be able to do so, you need:
* The private .pem file from the key pair defined when creating the cluster
* Using an IP in the management CIDR range defined when creating the cluster
* The public IP of the EC2 instance in the cluster you want to connect to
  * You can get this from the EC2 section directly, or going through ECS->Clusters->ECS Instances, and clicking the instance you want

Once you have the pre-requirements, you can simply ssh using the following command (replacing the pem path, and IP address):

    ssh -i "K:\pem\key-virginia.pem" ec2-user@34.200.215.102

You can then run commands such as 'docker ps' to see what is running.
