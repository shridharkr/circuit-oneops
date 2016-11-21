include_pack "genericlb"

name "iis"
description "Internet Information Services(IIS)"
type "Platform"
category "Web Server"

environment "single", {}
environment "redundant", {}

variable "platform_deployment",
  :description => 'Downloads the nuget packages',
  :value       => 'e:\platform_deployment'

variable "app_directory",
  :description => 'Application directory',
  :value       => 'e:\apps'

variable "nuget_exe",
  :description => 'Nuget exe path',
  :value       => 'C:\ProgramData\chocolatey\lib\NuGet.CommandLine\tools\NuGet.exe'

variable "log_directory",
  :description => 'Log directory',
  :value       => 'e:\logs'

variable "drive_name",
  :description => 'drive name',
  :value       => 'E'

resource "iis-website",
  :cookbook     => "oneops.1.iis-website",
  :design       => true,
  :requires     => {
    :constraint => "1..1",
    :help       => "Installs/Configure IIS"
  },
  :attributes   => {
    "site_name"     => '',
    "app_pool_name" => '',
    "physical_path" => '$OO_LOCAL{app_directory}'
  }

resource "dotnetframework",
  :cookbook     => "oneops.1.dotnetframework",
  :design       => true,
  :requires     => {
    :constraint => "1..1",
    :help       => "Installs .net frameworks",
    :services   => '*mirror'
  },
  :attributes   => {
    "chocolatey_package_source" => 'https://chocolatey.org/api/v2/',
    "dotnet_version_package_name" => '{ ".Net 4.6":"dotnet4.6", ".Net 3.5":"dotnet3.5" }'
  }

nuget_package_configure_cmd=  <<-"EOF"

nuget = '$OO_LOCAL{nuget_exe}'
package_name = node.artifact.repository
depends_on = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /website/ }
physical_path = depends_on.first[:ciAttributes][:physical_path]
site_name = depends_on.first[:ciAttributes][:site_name]
package_physical_path = ::File.join(physical_path, package_name)
website_physical_path = ::File.join(physical_path, site_name)

[package_physical_path, website_physical_path].each do |path|
  directory path do
    action :delete
    recursive true
  end
end

powershell_script "Install package #\{package_name\}" do
  code "#\{nuget\} install #\{package_name\} -Source #\{artifact_cache_version_path\} -outputdirectory #\{physical_path\} -ExcludeVersion -NoCache"
end

powershell_script "Renaming package folder #\{package_physical_path\} to #\{site_name\}" do
  guard_interpreter :powershell_script
  code "Rename-Item #\{package_physical_path\} #\{site_name\}"
  not_if "Test-Path #\{website_physical_path\}"
end


EOF

resource "nuget-package",
  :cookbook      => "oneops.1.artifact",
  :design        => true,
  :requires      => {
    :constraint  => "1..*",
    :help        => "Installs nuget package"
  },
  :attributes       => {
     :repository    => '',
     :location      => '',
     :install_dir   => '$OO_LOCAL{platform_deployment}',
     :as_user       => 'oneops',
     :as_group      => 'oneops',
     :should_expand => 'true',
     :configure     => nuget_package_configure_cmd,
     :migrate       => '',
     :restart       => ''
  },
  :payloads => {
    'iis-website' => {
      'description' => 'iis-website',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.oneops.1.Artifact",
         "relations": [
           { "returnObject": true,
             "returnRelation": false,
             "relationName": "manifest.DependsOn",
             "direction": "to",
             "targetClassName": "manifest.oneops.1.Iis-website"
           }
         ]
      }'
    }
  }

resource "secgroup",
  :attributes => {
    "inbound" => '[ "22 22 tcp 0.0.0.0/0", "3389 3389 tcp 0.0.0.0/0", "80 80 tcp 0.0.0.0/0"]'
  }

resource "os",
  :attributes => {
    "ostype"  => "windows_2012_r2"
  }

resource "volume",
  :requires       => {
    :constraint   => "1..1"
  },
  :attributes     => {
    "mount_point" => '$OO_LOCAL{drive_name}'
  }

[ { :from => 'iis-website', :to => 'dotnetframework' },
  { :from => 'dotnetframework', :to => 'os' },
  { :from => 'nuget-package', :to => 'iis-website' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

[ 'iis-website', 'nuget-package', 'dotnetframework', 'volume', 'os' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
