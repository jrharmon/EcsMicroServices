$defaultProfile = ""
$defaultRegion = "us-east-1"
$defaultClusterInstanceType = "t2.small"
$defaultClusterKeyPair = "mykey"
$defaultManagementCidr = "127.0.0.1/32" #the CIDR range of IPs allowed to SSH into a cluster
$defaultRootServiceHostName = "" #services will get a url of $servicename.$rootServiceHostName.  this should be your Route 53 hosted zone, without the trailing .
$defaultEcsServiceRole = "ecsServiceRole" #the role the ECS service uses to start/stop tasks (not the role that the real service runs as)

$bitBucketHostName = "" #the host name of the BitBucket (formerly Stash) server for the Git repository