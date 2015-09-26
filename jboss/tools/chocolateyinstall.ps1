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

# Now parse the packageParameters using good old regular expression
$arguments = @{};
$packageParameters = $env:chocolateyPackageParameters;

if($packageParameters) {
	Write-Host "PackageParameters: $packageParameters"
	$MATCH_PATTERN = "/([a-zA-Z]+)=(.*)"
	$PARAMATER_NAME_INDEX = 1
	$VALUE_INDEX = 2
	 
	if($packageParameters -match $MATCH_PATTERN){
	  $results = $packageParameters | Select-String $MATCH_PATTERN -AllMatches
	   
	  $results.matches | % { 
		  $arguments.Add(
			$_.Groups[$PARAMATER_NAME_INDEX].Value.Trim(),
			$_.Groups[$VALUE_INDEX].Value.Trim())
	  }
	  
	} else {
	  Write-Host "Default packageParameters will be used"
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

Write-Host "Copy to $installationPath\ from $installationPath\jboss-as-7.1.1.Final"
cp -Recurse -Force $installationPath\jboss-as-7.1.1.Final\* $installationPath\jboss-as-7.1.1.Final\..\

Write-Host "Remove $installationPath\jboss-as-7.1.1.Final"
rm -Force -Recurse $installationPath\jboss-as-7.1.1.Final

Install-ChocolateyEnvironmentVariable -variableName "JBOSS_HOME" -variableValue "$installationPath" -variableType 'Machine'
Install-ChocolateyPath "$installationPath\bin" "Machine"
Update-SessionEnvironment

#Add admin user to JBoss
Write-Host "Adding management user to JBoss"
$hashPass = hash ($jbossAdmin + ":ManagementRealm:" + $jbossPass)
$jbossUser = "$jbossAdmin=$hashPass" 
Write-Debug "Admin user hash: $jbossUser"
Write-Host ([Environment]::NewLine)$jbossUser |
        Out-File  $installationPath\standalone\configuration\mgmt-users.properties -Append -Encoding utf8

Write-Debug "Checking for JBOSS service..."
$jbossSvc = Get-Service jboss*
if($jbossSvc -eq $null){
	Write-Host "Installing JBoss Service"
	#$serviceUrl = "http://downloads.jboss.org/jbossnative/2.0.10.GA/jboss-native-2.0.10-windows-x86-ssl.zip"
	#$serviceUrl64 = "http://downloads.jboss.org/jbossnative/2.0.10.GA/jboss-native-2.0.10-windows-x64-ssl.zip"
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

    #echo "Downloading $__jbossServiceDownloadUrl"
    #wget $__jbossServiceDownloadUrl -OutFile $__tempFolder\jboss-svc.zip           
    #echo "JBOSS Service downloaded"
    #echo "Installing JBOSS Service"       
    #unzip $__tempFolder\jboss-svc.zip $env:JBOSS_HOME
        
    cp $toolsDir\..\assets\service.bat $installationPath\bin\service.bat -force
    
    &$installationPath\bin\service.bat install

    Set-Service jboss -StartupType Automatic
              
}
Write-Host "JBoss service installed"