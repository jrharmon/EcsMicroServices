#make sure Docker is pointing at the docker host
docker-machine env mydock | Invoke-Expression

#build the dev image
docker build -t {SERVICE} -f Dockerfile.dev .

#display the address to use
$dockerIp = (docker-machine ip mydock)
Write-Host
Write-Host "Service URL: http://$($dockerIp):{DEVPORT}/"
Write-Host

#run the image interactively, and kill it when done
docker run -it --rm -p {DEVPORT}:80 --name {SERVICE} {SERVICE}
