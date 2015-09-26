$ErrorActionPreference = 'Stop'; # stop on all errors
$packageName = 'jboss'
$shouldUninstall = $true

$installationPath = Get-EnvironmentVariable "JBOSS_HOME" "Machine"

if($installationPath -eq $null){
	$installationPath = "c:\opt\jboss"
}

Write-Debug "Checking for JBOSS service..."
$jbossSvc = Get-Service jboss*
if($jbossSvc -ne $null){
	Stop-Service jboss
	#&$installationPath\bin\service.bat uninstall
	&sc.exe delete jboss
}

if((test-path $installationPath) -eq $false){
    Write-Host "$packageName has already been uninstalled by other means."
    $shouldUninstall = $false
}

if($shouldUninstall -eq $true){
	
	Write-Host "Remove $installationPath"
	rm -Force -Recurse $installationPath	
	Uninstall-ChocolateyZipPackage $packageName "jbossInstall.zip"
}

Install-ChocolateyEnvironmentVariable "JBOSS_HOME" $null "Machine"
	
$path = Get-EnvironmentVariable "PATH" "Machine"
Write-Host "Current path: $path"

$newPath = $path.Replace("$installationPath\bin;", $null)
Write-Host "New Path: $newPath"

Install-ChocolateyEnvironmentVariable "PATH" $newPath "Machine"

Update-SessionEnvironment