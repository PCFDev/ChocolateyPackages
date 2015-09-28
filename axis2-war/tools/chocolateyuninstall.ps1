$ErrorActionPreference = 'Stop';

Uninstall-ChocolateyZipPackage -PackageName $env:chocolateyPackageName
Uninstall-ChocolateyZipPackage -PackageName $env:chocolateyPackageName -ZipFileName axis2.war

