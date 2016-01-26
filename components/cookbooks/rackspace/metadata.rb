name             "Rackspace"
description      "Compute Cloud Service"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true


attribute 'tenant',
  :description => "Tenant",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Tenant Name',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'username',
  :description => "Username",
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Username',
    :category => '1.Authentication',
    :order => 3
  }

attribute 'password',
  :description => "Password",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Password',
    :category => '1.Authentication',
    :order => 4
  }

attribute 'region',
  :description => "Region",
  :default => "",
  :format => {
    :help => 'Region Name',
    :category => '2.Placement',
    :order => 1
  }

attribute 'subnet',
  :description => "Subnet Name",
  :default => "",
  :format => {
    :help => 'Subnet Name is optional for placement of compute instances',
    :category => '2.Placement',
    :order => 2
  }

attribute 'sizemap',
  :description => "Sizes Map",
  :data_type => "hash",
  :default => '{ "XS":"2","S":"3","M":"4","L":"5","XL":"6" }',
  :format => {
    :help => 'Map of generic compute sizes to provider specific',
    :category => '3.Mappings',
    :order => 1
  }

attribute 'imagemap',
  :description => "Images Map",
  :data_type => "hash",
  :default => '{"ubuntu-14.04":"",
                "ubuntu-13.10":"",
                "ubuntu-13.04":"",
                "ubuntu-12.10":"",
                "ubuntu-12.04":"",
                "ubuntu-10.04":"",
                "redhat-7.0":"",
                "redhat-6.5":"",
                "redhat-6.4":"",
                "redhat-6.2":"",
                "redhat-5.9":"",
                "centos-7.0":"",
                "centos-6.5":"",
                "centos-6.4":"",
                "fedora-20":"",
                "fedora-19":""}',
  :format => {
    :help => 'Map of generic OS image types to provider specific 64-bit OS image types',
    :category => '3.Mappings',
    :order => 2
  }

attribute 'repo_map',
  :description => "OS Package Repositories keyed by OS Name",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Map of repositories by OS Type containing add commands - ex) yum-config-manager --add-repo repository_url or deb http://us.archive.ubuntu.com/ubuntu/ hardy main restricted ',
    :category => '4.Operating System',
    :order => 2
  }

attribute 'env_vars',
  :description => "System Environment Variables",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Environment variables - ex) http => http://yourproxy, https => https://yourhttpsproxy, etc',
    :category => '4.Operating System',
    :order => 2
  }

# operating system
attribute 'ostype',
  :description => "OS Type",
  :required => "required",
  :default => "centos-7.0",
  :format => {
    :help => 'OS types are mapped to the correct cloud provider OS images - see provider documentation for details',
    :category => '4.Operating System',
    :order => 4,
    :form => { 'field' => 'select', 'options_for_select' => [
      ['Ubuntu 14.04 (trusty)','ubuntu-14.04'],
      ['RedHat 7.0','redhat-7.0'],
      ['CentOS 7.0','centos-7.0'] ]
    }
  }
