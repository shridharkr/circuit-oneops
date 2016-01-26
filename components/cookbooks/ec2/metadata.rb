name             "Ec2"
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

attribute 'key',
  :description => "Access Key",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Access key from the provider security credentials page',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'secret',
  :description => "Secret Key",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'Secret key from the provider security credentials page',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'region',
  :description => "Region",
  :default => "",
  :format => {
    :help => 'Region Name',
    :category => '2.Placement',
    :order => 1
  }

attribute 'availability_zones',
  :description => "Availability Zones",
  :data_type => "array",
  :default => '[]',
  :format => {
    :help => 'Availability Zones - Singles will round robin, Redundant will use platform id',
    :category => '2.Placement',
    :order => 2
  }  
  
attribute 'subnet',
  :description => "Subnet Name",
  :default => "",
  :format => {
    :help => 'Subnet Name is optional for placement of compute instances',
    :category => '2.Placement',
    :order => 3
  }

attribute 'sizemap',
  :description => "Sizes Map",
  :data_type => "hash",
  :default => '{
      "XS":"t1.micro",
      "S":"m1.small",
      "M":"m1.medium",
      "L":"m1.large",
      "XL":"m3.xlarge",
      "XXL":"m3.2xlarge",
      "4XL":"",
      "S-CPU":"c1.medium",
      "M-CPU":"c3.large",
      "L-CPU":"c3.xlarge",
      "XL-CPU":"c3.2xlarge",
      "XXL-CPU":"c3.4xlarge",
      "4XL-CPU":"c3.8xlarge",
      "S-MEM":"",
      "M-MEM":"",
      "L-MEM":"m2.xlarge",
      "XL-MEM":"m2.2xlarge",
      "XXL-MEM":"m2.4xlarge",
      "4XL-MEM":"cr1.8xlarge",
      "S-IO":"",
      "M-IO":"",
      "L-IO":"c1.xlarge",
      "XL-IO":"cc2.8xlarge",
      "XXL-IO":"hi1.4xlarge",
      "4XL-IO":"hs1.8xlarge"
    }',
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
  :default => "ubuntu-14.04",
  :format => {
    :help => 'OS types are mapped to the correct cloud provider OS images - see provider documentation for details',
    :category => '4.Operating System',
    :order => 3,
    :form => { 'field' => 'select', 'options_for_select' => [
      ['Ubuntu 14.04 (trusty)','ubuntu-14.04'],
      ['RedHat 7.0','redhat-7.0'],
      ['CentOS 7.0','centos-7.0'] ] }
  }
