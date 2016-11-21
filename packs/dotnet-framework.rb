include_pack "genericlb"

name "dotnet-framework"
description ".Net Framework"
type "Platform"
category "Worker Application"

environment "single", {}
environment "redundant", {}

resource "dotnetframework",
  :cookbook     => "oneops.1.dotnetframework",
  :design       => true,
  :requires     => {
    :constraint => "1..1",
    :help       => "Installs .net frameworks",
    :services   => '*mirror'
  },
  :attributes   => {
    "chocolatey_package_source" => 'https://chocolatey.org/api/v2/'
  }

resource "secgroup",
  :attributes => {
    "inbound" => '[ "22 22 tcp 0.0.0.0/0", "3389 3389 tcp 0.0.0.0/0" ]'
  }

resource "os",
  :attributes => {
    "ostype"  => "windows_2012_r2"
  }

[ { :from => 'dotnetframework',  :to => 'os' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource => link[:to],
    :attributes => { "flex" => false, "min" => 1, "max" => 1 }
end

[ 'dotnetframework'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource => 'compute',
    :attributes => { }
end
