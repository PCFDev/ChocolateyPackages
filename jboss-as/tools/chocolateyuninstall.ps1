$ErrorActionPreference = 'Stop'; # stop on all errors
$packageName = 'jboss'


Write-Debug "Checking for JBOSS service..."
$jbossSvc = Get-Service jboss*
if($jbossSvc -ne $null){
	Stop-Service jboss
	&sc.exe delete jboss
}

Uninstall-ChocolateyZipPackage $packageName "jboss-ServiceInstall.zip"

Install-ChocolateyEnvironmentVariable "JBOSS_HOME" $null "Machine"

$path = Get-EnvironmentVariable "PATH" "Machine"
Write-Host "Current path: $path"

$installationPath = Get-EnvironmentVariable "JBOSS_HOME" "Machine"	
$newPath = $path.Replace("$installationPath\bin;", $null)
Write-Host "New Path: $newPath"

Install-ChocolateyEnvironmentVariable "PATH" $newPath "Machine"

Update-SessionEnvironment