$ErrorActionPreference = 'Stop'; # stop on all errors
$packageName = 'jboss'
$shouldUninstall = $true

$installationPath = Get-EnvironmentVariable "JBOSS_HOME" "Machine"

if((test-path $installationPath) -eq $false){
    Write-Host "$packageName has already been uninstalled by other means."
    $shouldUninstall = $false
}

if($shouldUninstall -eq $true){
	Uninstall-ChocolateyZipPackage
	Install-ChocolateyEnvironmentVariable "JBOSS_HOME" $null "Machine"
	
	$path = Get-EnvironmentVariable "PATH" "Machine"
	Write-Host "Current path: $path"
	
	$newPath = $path.Replace("$installationPath\bin", $null)
	Write-Host "New Path: $newPath"
	
	Install-ChocolateyEnvironmentVariable "PATH" $newPath "Machine"
	
	Update-SessionEnvironment
}

