function hash([string] $value){    
    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = new-object -TypeName System.Text.UTF8Encoding
    $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($value))).ToLower().Replace('-', '')
    echo $hash
}

$ErrorActionPreference = 'Stop'
$packageName = 'jboss'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url = 'http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip'

$arguments = @{}

$packageParameters = $env:chocolateyPackageParameters

$installationPath = "c:\opt\jboss"
$jbossAdmin = "admin"
$jbossPass = "password"
$startService = "true"

$arguments = @{};
$packageParameters = $env:chocolateyPackageParameters;

if($packageParameters) {
	Write-Host "PackageParameters: $packageParameters"
	
	$match_pattern = "\/(?<option>([a-zA-Z]+)):(?<value>([`"'])?([a-zA-Z0-9- _\\:\.\$]+)([`"'])?)|\/(?<option>([a-zA-Z]+))"
	
	#""" fixes issues with notepad++
	
	$option_name = 'option'
    $value_name = 'value'

	if ($packageParameters -match $match_pattern ){
	  $results = $packageParameters | Select-String $match_pattern -AllMatches
	  $results.matches | % {
			$arguments.Add(
				$_.Groups[$option_name].Value.Trim(),
				$_.Groups[$value_name].Value.Trim())
		}
	}
	else
	{
	  Throw "Package Parameters were found but were invalid (REGEX Failure)"
	}

	 
	if($arguments.ContainsKey("InstallationPath")) {
	  $installationPath = $arguments["InstallationPath"];
	  Write-Host "Value variable installationPath changed to $installationPath"
	} else {
	  Write-Host "Default InstallationPath will be used"
	}

	if($arguments.ContainsKey("Username")) {
	  $jbossAdmin = $arguments["Username"];
	  Write-Host "Admin username changed to $jbossAdmin"
	} else {
	  Write-Host "Default admin username will be used"
	}

	if($arguments.ContainsKey("Password")) {
	  $jbossPass = $arguments["Password"];
	  Write-Host "Admin password changed to $jbossPass"
	} else {
	  Write-Host "Default admin password will be used. PLEASE CHANGE THIS!!!"
	}
	
	if($arguments.ContainsKey("Start")) {
	  $startService = $arguments["Start"];
	  Write-Host "Start service? $startService"
	} else {
	  Write-Host "Service will be automatically started"
	}
	
} else {
	Write-Host "Package parameters will not be overwritten"
}

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $installationPath
  url           = $url
  checksum      = '175c92545454f4e7270821f4b8326c4e'
  checksumType  = 'md5'  
}

Install-ChocolateyZipPackage @packageArgs

Write-Debug "Copy to $installationPath\ from $installationPath\jboss-as-7.1.1.Final"
cp -Recurse -Force $installationPath\jboss-as-7.1.1.Final\* $installationPath\jboss-as-7.1.1.Final\..\

Write-Debug "Remove $installationPath\jboss-as-7.1.1.Final"
rm -Force -Recurse $installationPath\jboss-as-7.1.1.Final

Install-ChocolateyEnvironmentVariable -variableName "JBOSS_HOME" -variableValue "$installationPath" -variableType 'Machine'
Install-ChocolateyPath "$installationPath\bin" "Machine"
Update-SessionEnvironment

Write-Verbose "Adding management user to JBoss"
$hashPass = hash ($jbossAdmin + ":ManagementRealm:" + $jbossPass)
$jbossUser = "$jbossAdmin=$hashPass" 
Write-Debug "Admin user hash: $jbossUser ==>  $installationPath\standalone\configuration\mgmt-users.properties"

Add-Content $installationPath\standalone\configuration\mgmt-users.properties "`r`n$jbossUser" -Encoding utf8

Write-Verbose "Checking for JBOSS service..."
$jbossSvc = Get-Service jboss*
if($jbossSvc -eq $null){
	Write-Host "Installing JBoss Service"
	
	Write-Debug "Service unzipLocation $installationPath"
	
	$servicePackageArgs = @{
		packageName   = "$packageName-Service"
		unzipLocation = $installationPath
		url           = "http://downloads.jboss.org/jbossnative/2.0.10.GA/jboss-native-2.0.10-windows-x86-ssl.zip"
		url64bit      = "http://downloads.jboss.org/jbossnative/2.0.10.GA/jboss-native-2.0.10-windows-x64-ssl.zip"
 
		checksum    = 'acc45d49f1838183726bf616f0069cfc'
		checksumType= 'md5'
		checksum64    = '63477e8e166c9ec695ab2922ca0a31b0'
		checksumType64= 'md5'
	}
		
	Install-ChocolateyZipPackage @servicePackageArgs
     
    cp $toolsDir\..\assets\service.bat $installationPath\bin\service.bat -force
    
    &$installationPath\bin\service.bat install

    Set-Service jboss -StartupType Automatic
	
	if($startService -eq "true"){
		Write-Host "Starting Service"
		Start-Service jboss
	} else {
		Write-Host "Start service set to $startService"
	}
              
}
Write-Host "JBoss service installed"