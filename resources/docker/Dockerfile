FROM microsoft/dotnet:1.1-sdk AS build-env
WORKDIR /app

# copy csproj and restore dependencies
# as long as the .csproj file is not updated, these commands will used cached images, so you aren't doing a restore for every build
COPY {SERVICE}.csproj ./
RUN dotnet restore

# copy and build everything else
COPY . ./
RUN dotnet publish -c Release -o out



FROM microsoft/dotnet:1.1-runtime
WORKDIR /app
COPY --from=build-env /app/out ./

#expose environment variables within the image
ENV ASPNETCORE_URLS http://*:80
ENV ASPNETCORE_ENVIRONMENT Production
EXPOSE 80

#run the service on startup
ENTRYPOINT ["dotnet", "{SERVICE}.dll"]