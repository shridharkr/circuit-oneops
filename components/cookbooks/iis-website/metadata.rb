name             'Iis-website'
maintainer       'Oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'This cookbook creates/configures iis website'
version          '0.1.0'

supports 'windows'
depends 'iis'

grouping 'default',
  :access   => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'site_name',
  :description => 'Web Site name',
  :required    => "required",
  :format      => {
    :help      => 'Name of the IIS website to create',
    :category  => '1.IIS Web site',
    :order     => 1
  }

attribute 'physical_path',
  :description => 'Web Site Physical Path',
  :required    => "required",
  :format      => {
    :help      => 'Website physical path',
    :category  => '1.IIS Web site',
    :order     => 2
  }

attribute 'binding_type',
  :description => 'Binding Type',
  :default     => 'http',
  :required    => "required",
  :format      => {
    :help      => 'IIS binding type http or https',
    :category  => '2.IIS Bindings',
    :order     => 1,
    :form      => { 'field' => 'select', 'options_for_select' => [['http','http'],['https','https']] }
  }

attribute 'binding_port',
  :description => 'Binding Port',
  :default     => '80',
  :required    => "required",
  :format      => {
    :help      => 'IIS binding port',
    :category  => '2.IIS Bindings',
    :order     => 2
  }

attribute 'app_pool_name',
  :description => 'Application pool name',
  :required    => "required",
  :format      => {
    :help      => 'Name of the application pool to create/configure',
    :category  => '3.IIS Application pool',
    :order     => 1
  }

attribute 'runtime_version',
:description => '.Net CLR version',
:required    => "required",
:default     => "v4.0",
:format      => {
  :help      => 'The version of .Net CLR runtime that the appplication pool will use',
  :category  => '3.IIS Application pool',
  :order     => 2,
  :form      => { 'field' => 'select', 'options_for_select' => [['v2.0','v2.0'],['v4.0','v4.0']] }
}

attribute 'identity_type',
  :description => 'Indentity type',
  :required    => 'required',
  :default     => 'Application Pool Identity',
  :format      => {
  :help        => 'Select the built-in account which application pool will use',
    :category  => '3.IIS Application pool',
    :order     => 2,
    :form      => { 'field' => 'select', 'options_for_select' => [['Application Pool Identity', 'ApplicationPoolIdentity'],['Local System','LocalSystem'],['Network Service','NetworkService'],['Local Service','LocalService']] }
}
