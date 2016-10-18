
param([string]$proxy="", [string]$chocoPkg="", [string]$chocoRepo="", [string]$gemRepo="")

function Download-File {
  param ( [string]$proxy, [string]$uri, [string]$dir, [string]$destination )

  #Create the directory if it does not exists
  New-Item -ItemType Directory -Force -Path $dir

  $start_time = Get-Date

  try {
     Invoke-WebRequest -Uri $uri -OutFile $destination
  }
  catch {
     Write-Output "Could not download from $uri "
     Write-Output " applying proxy ... "
     try {
        Invoke-WebRequest -Uri $uri -Proxy $proxy -OutFile $destination
     }
     catch {
        Write-Error "Could not download chocolatey. Cannot continue. Exiting!!! "
        exit 1
     }
  }
  finally {
     Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
  }
}


function Expand-ZIPFile {
  param([string]$file, [string]$destination)
  $shell = New-Object  -ComObject  Shell.Application
  $zip = $shell.NameSpace($file)

  #make sure destination exists
  #Create-DirectoryIfNotExists $destination
  New-Item -ItemType Directory -Force -Path $destination

  $shell.Namespace($destination).CopyHere($zip.Items(), 0x10)

}

## =====================================================

Write-Output "install_base param proxy: $proxy "
Write-Output "install_base param choco pkg: $chocoPkg "
Write-Output "install_base param choco repo: $chocoRepo "
Write-Output "install_base param gem repo: $gemRepo "

if( $chocoPkg -eq $null -or $chocoPkg -eq "" ) {
  $chocoPkg = "https://packages.chocolatey.org/chocolatey.0.9.9.12.nupkg"
}

$chocoTempDir = "c:\chocotemp\"
$chocoTempFile = "c:\chocotemp\choco.zip"


Write-Output "Downloading chocolatey ..."
Download-File $proxy $chocoPkg $chocoTempDir $chocoTempFile

try
{
Set-Location $chocoTempDir

Write-Output "Extracting chocolatey zipfile "
$chocoDir = "C:\Chocolatey"

Get-ChildItem $chocoTempDir -Filter *.zip |
Foreach-Object{
    Expand-ZIPFile $_.FullName  $chocoDir
}

$toolsFolder = Join-Path $chocoDir "tools"

$chocoInstallPS = Join-Path $toolsFolder "chocolateyInstall.ps1"

Write-Output "Installing Chocolatey ..."
& $chocoInstallPS

Set-Location "C:\"
Remove-Item -Recurse -Force $chocoTempDir

## =======================================
if ( $proxy -ne "" -and $proxy -ne $null) {
    choco config set proxy $proxy
}

if ( $chocoRepo -ne "" -and $chocoRepo -ne $null ) {
    #choco source disable -y --name="chocolatey"
    choco source add -y --name='internal' --source=$chocoRepo --priority=1
}

Write-Output "Install ruby ..."
choco install -y ruby
refreshenv

Write-Output "Install nuget.commandline ..."
choco install -y nuget.commandline

Write-Output "Install ruby DevKit ..."
choco install -y ruby2.devkit
refreshenv

###########################################
Set-Location "C:\tools\DevKit2\"
Add-Content config.yml "`n- C:/tools/ruby23"
###########################################

if ($($env:Path).ToLower().Contains("devkit") -eq $false) {
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\tools\DevKit2\bin", [EnvironmentVariableTarget]::Machine)
    refreshenv
}

#ruby dk.rb init
ruby dk.rb install

gem source --add $gemRepo

Write-Output "Installing json ..."
gem install json --version 1.8.2 --no-ri --no-rdoc

#Write-Output "Installing Bundler ..."
#gem install bundler --version 1.10.5 --no-ri --no-rdoc

Add-Content C:\cygwin64\home\admin\.bash_profile 'export PATH=$PATH:/cygdrive/c/tools/ruby23/bin/'
New-Item C:\cygwin64\opt\admin\workorder\ -ItemType directory

Add-Content C:\cygwin64\home\oneops\.bash_profile 'export PATH=$PATH:/cygdrive/c/tools/ruby23/bin:/cygdrive/c/tools/DevKit2'
New-Item -ItemType Directory -Force -Path C:\cygwin64\opt\oneops\workorder\

New-Item C:\cygwin64\opt\oneops\rubygems_proxy -type file -force
Set-Content C:\cygwin64\opt\oneops\rubygems_proxy $gemRepo

Set-Location "C:\"
    Write-Output "End of windows install_base script"
}
catch 
{
    Write-Error $_.Exception.Message
    exit 1
}
