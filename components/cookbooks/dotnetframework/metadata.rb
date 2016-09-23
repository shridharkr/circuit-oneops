name             'Dotnetframework'
maintainer       'Oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'This cookbook install .net frameworks'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

supports 'windows'
depends 'chocolatey', '= 0.4.0'

grouping 'default',
  :access   => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'chocolatey_package_source',
  :description => 'Package url',
  :default     => 'https://chocolatey.org/api/v2/',
  :required    => "required",
  :format      => {
    :help      => 'Chocolatey package url for the .net framework chocolatey packages',
    :category  => '1.Chocolatey Package Source',
    :order     => 1
  }

attribute 'dotnet_framework_version',
  :description => 'Framework version',
  :default     => '.Net 4.5.2',
  :format      => {
  :help        => 'Select the .net framework versions to be installed',
    :category  => '2.Framework Version',
    :order     => 1,
    :form      => { 'field' => 'select', 'options_for_select' => [['.Net 3.5','dotnet3.5'],['.Net 4.5.2','dotnet4.5.2'], ['.Net 4.6','dotnet4.6']] }
  }
