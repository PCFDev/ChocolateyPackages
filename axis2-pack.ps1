#
# axis2_pack.ps1
#
choco pack axis2\axis2.nuspec
mv -force axis2.1.6.1.nupkg _packages\