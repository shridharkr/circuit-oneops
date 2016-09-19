
param([string]$proxy, [string]$chocoPkg, [string]$chocoRepo, [string]$gemRepo)


function Download-File {
  param ( [string]$proxy, [string]$chocoPkg, [string]$dir, [string]$destination )

  #Create the directory if it does not exists
  New-Item -ItemType Directory -Force -Path $dir

  $start_time = Get-Date

  try {
     Invoke-WebRequest -Uri $chocoPkg -OutFile $destination
  }
  catch {
     Write-Output "Could not download from $chocoPkg "
     Write-Output " applying proxy ... "
     try {
        Invoke-WebRequest -Uri $chocoPkg -Proxy $proxy -OutFile $destination
     }
     catch {
        Write-Output "Cloud not download chocolatey. Cannot continue. Exiting!!! "
        exit
     }
  }
  finally {
    if(Test-Path $destination) {
      Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    }
    else {
      Write-Output "The downloaded file does not exist. Exiting!"
      exit
    }
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

$chocoTempDir = "C:\chocotemp\"
$chocoTempFile = "C:\chocotemp\choco.zip"


Write-Output "Downloading chocolatey..."
Download-File $proxy $chocoPkg $chocoTempDir $chocoTempFile

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

#choco config set proxy $proxy
choco source disable --name="chocolatey"
choco source add --name='internal' --source=$chocoRepo

Write-Output "Install ruby ..."
choco install -y ruby

Write-Output "Install ruby DevKit ..."
choco install -y ruby2.devkit


###########################################
Set-Location "C:\tools\DevKit2\"
Set-Content config.yml "---"
Set-Content config.yml "- C:/tools/ruby23"
###########################################

# Set the latest path to the current session, so that we get the latest path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$env:Path += ";C:\cygdrive\c\tools\ruby23\bin;C:\tools\DevKit2\bin"

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
