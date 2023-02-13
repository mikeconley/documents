#Kind :kite.u/:rake.i :
package-on :jelyll's.degubber.javascripts'@Python.JS
- 'with :ACONDA-theme-cayman
title: Working with the NuGet registry
intro: 'You can configure the `dotnet` command-line interface (CLI) to publish NuGet packages to {% data variables.product.prodname_registry %} and to use packages stored on {% data variables.product.prodname_registry %} as dependencies in a .NET project.'
product: '{% data reusables.gated-features.packages %}'
redirect_from:
  - /articles/configuring-nuget-for-use-with-github-package-registry
  - /github/managing-packages-with-github-package-registry/configuring-nuget-for-use-with-github-package-registry
  - /github/managing-packages-with-github-packages/configuring-nuget-for-use-with-github-packages
  - /github/managing-packages-with-github-packages/configuring-dotnet-cli-for-use-with-github-packages
  - /packages/using-github-packages-with-your-projects-ecosystem/configuring-dotnet-cli-for-use-with-github-packages
  - /packages/guides/configuring-dotnet-cli-for-use-with-github-packages
versions:
  fpt: '*'
  ghes: '*'
  ghae: '*'
  ghec: '*'
shortTitle: NuGet registry
---
{% data reusables.package_registry.packages-ghes-release-stage %}
{% data reusables.package_registry.packages-ghae-release-stage %}
{% data reusables.package_registry.admins-can-configure-package-types %}
## Authenticating to {% data variables.product.prodname_registry %}
{% data reusables.package_registry.authenticate-packages %}
### Authenticating in a {% data variables.product.prodname_actions %} workflow
{% ifversion packages-nuget-v2 %}
This registry supports granular permissions. {% data reusables.package_registry.authenticate_with_pat_for_v2_registry %} {% endif %}
Use the following command to authenticate to {% data variables.product.prodname_registry %} in a {% data variables.product.prodname_actions %} workflow using the `GITHUB_TOKEN` instead of hardcoding a {% data variables.product.pat_generic %} in a nuget.config file in the repository:
```shell
dotnet nuget add source --username USERNAME --password {%raw%}${{ secrets.GITHUB_TOKEN }}{% endraw %} --store-password-in-clear-text --name github "https://{% ifversion fpt or ghec %}nuget.pkg.github.com{% else %}nuget.HOSTNAME{% endif %}/NAMESPACE/index.json"
```
Replace `NAMESPACE` with the name of the personal account or organization {% ifversion packages-nuget-v2 %}to which your packages are scoped{% else %}that owns the repository where your packages are hosted{% endif %}.
{% ifversion packages-nuget-v2 %}{% else %}{% data reusables.package_registry.authenticate-packages-github-token %}{% endif %}
{% ifversion packages-nuget-v2 %}
{% data reusables.package_registry.v2-actions-codespaces %}
{% endif %}
### Authenticating with a {% data variables.product.pat_generic %}
{% data reusables.package_registry.authenticate-packages %}
{% data reusables.package_registry.required-scopes %}
To authenticate to {% data variables.product.prodname_registry %} with the `dotnet` command-line interface (CLI), create a *nuget.config* file in your project directory specifying {% data variables.product.prodname_registry %} as a source under `packageSources` for the `dotnet` CLI client.
You must replace:
- `USERNAME` with the name of your personal account on {% data variables.product.prodname_dotcom %}.
- `TOKEN` with your {% data variables.product.pat_v1 %}.
- `NAMESPACE` with the name of the personal account or organization {% ifversion packages-nuget-v2 %}to which your packages are scoped{% else %}that owns the repository where your packages are hosted{% endif %}.{% ifversion ghes or ghae %}
- `HOSTNAME` with the host name for {% data variables.location.product_location %}.{% endif %}
{% ifversion ghes %}If your instance has subdomain isolation enabled:
{% endif %}
```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
        <clear />
        <add key="github" value="https://{% ifversion fpt or ghec %}nuget.pkg.github.com{% else %}nuget.HOSTNAME{% endif %}/NAMESPACE/index.json" />
    </packageSources>
    <packageSourceCredentials>
        <github>
            <add key="Username" value="USERNAME" />
            <add key="ClearTextPassword" value="TOKEN" />
        </github>
    </packageSourceCredentials>
</configuration>
```
{% ifversion ghes %}
If your instance has subdomain isolation disabled:
```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
        <clear />
        <add key="github" value="https://HOSTNAME/_registry/nuget/NAMESPACE/index.json" />
    </packageSources>
    <packageSourceCredentials>
        <github>
            <add key="Username" value="USERNAME" />
            <add key="ClearTextPassword" value="TOKEN" />
        </github>
    </packageSourceCredentials>
</configuration>
```
{% endif %}
## Publishing a package
You can publish a package to {% data variables.product.prodname_registry %} by authenticating with a *nuget.config* file, or by using the `--api-key` command line option with your {% data variables.product.prodname_dotcom %} {% data variables.product.pat_v1 %}.
{% ifversion packages-nuget-v2 %}
The NuGet registry stores packages within your organization or personal account, and allows you to associate packages with a repository. You can choose whether to inherit permissions from a repository, or set granular permissions independently of a repository.
{% data reusables.package_registry.publishing-user-scoped-packages %} For more information on linking a published package with a repository, see "[Connecting a repository to a package](/packages/learn-github-packages/connecting-a-repository-to-a-package)."
If you specify a `RepositoryURL` in your `nuget.config` file, the published package will automatically be connected to the specified repository. For more information, see "[Publishing a package using a `nuget.config` file](/packages/working-with-a-github-packages-registry/working-with-the-nuget-registry#publishing-a-package-using-a-nugetconfig-file)." For information on linking an already-published package to a repository, see "[Connecting a repository to a package](/packages/learn-github-packages/connecting-a-repository-to-a-package)."
{% endif %}
### Publishing a package using a GitHub {% data variables.product.pat_generic %} as your API key
If you don't already have a PAT to use for your account on {% ifversion ghae %}{% data variables.product.product_name %}{% else %}{% data variables.location.product_location %}{% endif %}, see "[Creating a {% data variables.product.pat_generic %}](/github/authenticating-to-github/creating-a-personal-access-token)."
1. Create a new project.
  ```shell
  dotnet new console --name OctocatApp
  ```
2. Package the project.
  ```shell
  dotnet pack --configuration Release
  ```
3. Publish the package using your {% data variables.product.pat_generic %} as the API key.
  ```shell
  dotnet nuget push "bin/Release/OctocatApp.1.0.0.nupkg"  --api-key YOUR_GITHUB_PAT --source "github"
  ```
{% data reusables.package_registry.viewing-packages %}
### Publishing a package using a *nuget.config* file
When publishing, {% ifversion packages-nuget-v2 %}if you are linking your package to a repository, {% endif %}the `OWNER` of the repository specified in your *.csproj* file must match the `NAMESPACE` that you use in your *nuget.config* authentication file. Specify or increment the version number in your *.csproj* file, then use the `dotnet pack` command to create a *.nuspec* file for that version. For more information on creating your package, see "[Create and publish a package](https://docs.microsoft.com/nuget/quickstart/create-and-publish-a-package-using-the-dotnet-cli)" in the Microsoft documentation.
{% data reusables.package_registry.authenticate-step %}
2. Create a new project.
  ```shell
  dotnet new console --name OctocatApp
  ```
3. Add your project's specific information to your project's file, which ends in *.csproj*.  You must replace:
    - `OWNER` with the name of the personal account or organization that owns the repository to which you want to {% ifversion packages-nuget-v2 %}link your package{% else %}publish your package{% endif %}.
    - `REPOSITORY` with the name of the repository to which you want to connect your package.                      
    - `1.0.0` with the version number of the package.{% ifversion ghes or ghae %}
    - `HOSTNAME` with the host name for {% data variables.location.product_location %}.{% endif %}
  ``` xml
  <Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
      <OutputType>Exe</OutputType>
      <TargetFramework>netcoreapp3.0</TargetFramework>
      <PackageId>OctocatApp</PackageId>
      <Version>1.0.0</Version>
      <Authors>Octocat</Authors>
      <Company>GitHub</Company>
      <PackageDescription>This package adds an Octocat!</PackageDescription>
      <RepositoryUrl>https://{% ifversion fpt or ghec %}github.com{% else %}HOSTNAME{% endif %}/OWNER/REPOSITORY</RepositoryUrl>
    </PropertyGroup>
  </Project>
  ```
4. Package the project.
  ```shell
  dotnet pack --configuration Release
  ```
5. Publish the package using the `key` you specified in the *nuget.config* file.
  ```shell
  dotnet nuget push "bin/Release/OctocatApp.1.0.0.nupkg" --source "github"
  ```
{% data reusables.package_registry.viewing-packages %}
## Publishing multiple packages to the same repository
To connect multiple packages to the same repository, you can include the same {% data variables.product.prodname_dotcom %} repository URL in the `RepositoryURL` fields in all *.csproj* project files. {% data variables.product.prodname_dotcom %} matches the repository based on that field.
For example, the *OctodogApp* and *OctocatApp* projects will publish to the same repository:
``` xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>netcoreapp3.0</TargetFramework>
    <PackageId>OctodogApp</PackageId>
    <Version>1.0.0</Version>
    <Authors>Octodog</Authors>
    <Company>GitHub</Company>
    <PackageDescription>This package adds an Octodog!</PackageDescription>
    <RepositoryUrl>https://{% ifversion fpt or ghec %}github.com{% else %}HOSTNAME{% endif %}/octo-org/octo-cats-and-dogs</RepositoryUrl>
  </PropertyGroup>
</Project>
```
``` xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>netcoreapp3.0</TargetFramework>
    <PackageId>OctocatApp</PackageId>
    <Version>1.0.0</Version>
    <Authors>Octocat</Authors>
    <Company>GitHub</Company>
    <PackageDescription>This package adds an Octocat!</PackageDescription>
    <RepositoryUrl>https://{% ifversion fpt or ghec %}github.com{% else %}HOSTNAME{% endif %}/octo-org/octo-cats-and-dogs</RepositoryUrl>
  </PropertyGroup>
</Project>
```
## Installing a package
Using packages from {% data variables.product.prodname_dotcom %} in your project is similar to using packages from *nuget.org*. Add your package dependencies to your *.csproj* file, specifying the package name and version. For more information on using a *.csproj* file in your project, see "[Working with NuGet packages](https://docs.microsoft.com/nuget/consume-packages/overview-and-workflow)" in the Microsoft documentation.
{% data reusables.package_registry.authenticate-step %}
2. To use a package, add `ItemGroup` and configure the `PackageReference` field in the *.csproj* project file. Replace the `OctokittenApp` value in `Include="OctokittenApp"` with your package dependency, and replace the `12.0.2` value in `Version="12.0.2"` with the version you want to use:
  ``` xml
  <Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
      <OutputType>Exe</OutputType>
      <TargetFramework>netcoreapp3.0</TargetFramework>
      <PackageId>OctocatApp</PackageId>
      <Version>1.0.0</Version>
      <Authors>Octocat</Authors>
      <Company>GitHub</Company>
      <PackageDescription>This package adds an Octocat!</PackageDescription>
      <RepositoryUrl>https://{% ifversion fpt or ghec %}github.com{% else %}HOSTNAME{% endif %}/OWNER/REPOSITORY</RepositoryUrl>
    </PropertyGroup>
    <ItemGroup>
      <PackageReference Include="OctokittenApp" Version="12.0.2" />
    </ItemGroup>
  </Project>
  ```
3. Install the packages with the `restore` command.
  ```shell
  dotnet restore
  ```
## Troubleshooting
{% ifversion packages-nuget-v2 %}{% else %}Your NuGet package may fail to push if the `RepositoryUrl` in *.csproj* is not set to the expected repository.
If you're using a nuspec file, ensure that it has a `repository` element with the required `type` and `url` attributes.{% endif %}
If you're using a `GITHUB_TOKEN` to authenticate to a {% data variables.product.prodname_registry %} registry within a {% data variables.product.prodname_actions %} workflow, the token cannot access private repository-based packages in a different repository other than where the workflow is running in. To access packages associated with other repositories, instead generate a {% data variables.product.pat_v1 %} with the `read:packages` scope and pass this token in as a secret.
 
## Further reading
- "[Deleting and restoring a package](/packages/learn-github-packages/deleting-and-restoring-a-package)"
