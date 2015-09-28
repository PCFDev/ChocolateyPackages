#
# axis2_pack.ps1
#
choco pack axis2-war\axis2-war.nuspec
mv -force axis2-war.1.6.2.nupkg _packages\