# .NET Core Service Architecture

## Environment
.NET Core has a built-in notion of the environment it is running in.  By default, it assumes it is running in the 'Production' envioronment,
which means that it should be in its most locked-down state, unless specified otherwise.

[MS Documentation](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/environments)

### Setting the Environment
- Set as the environment variable ASPNETCORE_ENVIRONMENT
- Set in Properties\launchSettings.json
  - Seems to only effect Visual Studio, and not dotnet run
- Set in .vscode\launch.json when debugging with VS Code

### Checking the Environment
- Request IHostingEnvironment from DI, such as in Startup.Configure()
  - ex: public void Configure(IApplicationBuilder app, IHostingEnvironment env, ILoggerFactory loggerFactory) {}
- Use env.IsEnvironment("environmentname") instead of env.EnvironmentName == "name", since IsEnvironment ignores casing
- There are helper methods for common environments (.NET Core uses full names, instead of abbreviations, such as DEV, TST, STG or PRD)
  - ex: if (env.IsDevelopment()) {}

## Configuration

[Essential .NET Core Configuration](https://msdn.microsoft.com/en-us/magazine/mt632279.aspx?f=255&MSPPError=-2147217396)

### Environment Configs
Configuration settings are stored in appsettings.json, for common settings, and appsettings.[ENV].json for settings specific to an individual environment.
.NET Core has native support for loading settings from JSON files, as well as XML/INI files, environment variables or even command line arguments.


