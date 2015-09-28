$ErrorActionPreference = 'Stop';

$packageName = $env:chocolateyPackageName
$version = $env:chocolateyPackageVersion

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url = "http://archive.apache.org/dist/axis/axis2/java/core/$version/axis2-$version-war.zip"
$checksum = Get-WebFile "http://archive.apache.org/dist/axis/axis2/java/core/$version/axis2-$version-war.zip.md5" -Passthru
Write-Verbose "Downloaded checksum: $checksum"

$unzipLocation = "$toolsDir\temp"

$installationPath = "c:\temp\axis2.war"

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
	
} else {
	Write-Host "Package parameters will not be overwritten"
}

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $unzipLocation
  url           = $url
  checksum      =  $checksum
  checksumType  = 'md5'
}

Install-ChocolateyZipPackage @packageArgs
Get-ChocolateyUnzip "$unzipLocation\axis2.war" $installationPath -packageName $packageName

#include containing folder in the uninstall log file
$zipExtractLogFullPath= Join-Path $env:ChocolateyPackageFolder axis2.war.txt
Add-Content $zipExtractLogFullPath $installationPath
