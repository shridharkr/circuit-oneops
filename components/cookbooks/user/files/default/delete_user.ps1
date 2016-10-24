param([string]$userName="")

#################################################

Write-Host "Deleting $userName user from windows"

$Computername = $env:COMPUTERNAME
$ADSIComp = [adsi]"WinNT://$Computername"
$NewUser = $ADSIComp.Delete('User',$userName)

#################################################

Write-Host "Deleting $userName user from cygwin"

Remove-Item C:\cygwin64\home\$userName\* -Recurse
Remove-Item C:\cygwin64\home\$userName

## TODO: Cleanup
