dotnet restore
dotnet publish -c Release -o out

docker build -t {SERVICE} .