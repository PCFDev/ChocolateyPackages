$ErrorActionPreference = 'Stop'
$packageName = 'jboss'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url = 'http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip'

$arguments = @{}

$packageParameters = $env:chocolateyPackageParameters

$installationPath = "c:\opt\jboss"

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
	
} else {
	Write-Host "Package parameters will not be overwritten"
}

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  url           = $url
  checksum      = '175c92545454f4e7270821f4b8326c4e'
  checksumType  = 'md5'  
}

Install-ChocolateyZipPackage @packageArgs

Write-Host "Copy to $installationPath\ from $toolsDir\jboss-as-7.1.1.Final"
cp -Recurse -Force $toolsDir\jboss-as-7.1.1.Final\* $installationPath\

Write-Host "Remove $toolsDir\jboss-as-7.1.1.Final"
rm -Force -Recurse $toolsDir\jboss-as-7.1.1.Final

Install-ChocolateyEnvironmentVariable -variableName "JBOSS_HOME" -variableValue "$installationPath" -variableType 'Machine'
Install-ChocolateyPath "$installationPath\bin" "Machine"
Update-SessionEnvironment