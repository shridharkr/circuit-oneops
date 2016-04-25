name             'Azuredns'
maintainer       'oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'Installs/Configures Azure DNS'
version          '0.1.0'
depends          'azure'
#depends          'azuredns'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'tenant_id',
  :description => "Azure Tenant ID",
  :required => "required",
  :default => "Enter Tenant ID associated with Azure AD",
  :format => {
    :help => 'tenant id',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'subscription',
  :description => "Subscription Id",
  :required => "required",
  :default => "",
  :format => {
    :help => 'subscription id in azure',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'client_id',
  :description => "Client Id",
  :required => "required",
  :default => "",
  :format => {
    :help => 'client id',
    :category => '1.Authentication',
    :order => 3
  }

attribute 'client_secret',
  :description => "Client Secret",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'client secret',
    :category => '1.Authentication',
    :order => 4
  }

attribute 'zone',
  :description => "Zone",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Specify the zone name where to insert DNS records',
    :category => '2.DNS',
    :order => 1
  }

attribute 'cloud_dns_id',
  :description => "Cloud DNS Id",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Cloud DNS Id - prepended to zone name, but replaced w/ fqdn.global_dns_id for GLB',
    :category => '2.DNS',
    :order => 2
  }

attribute 'authoritative_server',
  :description => "authoritative_server",
  :default => "",
  :format => {
    :help => 'Explicit authoritative_server for verification - useful for testing. If not set uses NS records for the zone.',
    :category => '2.DNS',
    :order => 3
  }
