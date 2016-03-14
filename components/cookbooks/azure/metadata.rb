name             "Azure"
description      "Azure Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"
depends					 "azure"
depends					 "compute"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'service.compute', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'tenant_id',
          :description => "Tenant ID",
          :required => "required",
          :default => "Enter Tenant ID associated with Azure AD",
          :format => {
              :help => 'tenant id',
              :category => '1.Authentication',
              :order => 1
          }

attribute 'client_id',
          :description => "Client Id",
          :required => "required",
          :default => "",
          :format => {
              :help => 'client id',
              :category => '1.Authentication',
              :order => 2
          }

attribute 'subscription',
          :description => "Subscription Id",
          :required => "required",
          :default => "",
          :format => {
              :help => 'subscription id in azure',
              :category => '1.Authentication',
              :order => 3
          }

attribute 'client_secret',
          :description => "Client Secret",
          :encrypted => true,
          :required => "required",
          :default => "",
          :format => {
              :help => 'client secret azure',
              :category => '1.Authentication',
              :order => 4
          }

attribute 'location',
          :description => "Location",
          :required => "required",
          :default => "",
          :format => {
              :help => 'Azure cloud region',
              :category => '2.Network Section',
              :order => 1,
              :filter => {'all' => {'visible' => 'true:eq:false'}}
          }

attribute 'express_route_enabled',
          :description => "Express Route",
          :default => "false",
          :format => {
              :help => 'An Azure ExpressRoute is a private connections between Azure datacenters and your on-premise infrastructure. ExpressRoute connections do not go over the public Internet.',
              :category => '2.Network Section',
              :order => 2,
              :form => {'field' => 'checkbox'}
          }

attribute 'resource_group',
          :description => "Network Resource Group",
          :default => '',
          :format => {
              :help => 'Mandatory only for private (corporate address space, eg - express route), Fill this with master resource group name which has Predefined Private VNets.',
              :category => '2.Network Section',
              :order => 3,
              :filter => {'all' => {'visible' => 'express_route_enabled:eq:true'}}
          }

attribute 'network',
          :description => "Virtual Network Name",
          :default => '',
          :format => {
              :help => 'Mandatory only for private (corporate address space, eg - express route), Fill this with Predefined Private VNET and subnet (in the field below)name to use.Optional for public ip type,if empty new VNet and subnet will be created',
              :category => '2.Network Section',
              :order => 4,
              :filter => {'all' => {'visible' => 'express_route_enabled:eq:true'}}
          }

attribute 'network_address',
          :description => "Network Address Range",
          :default => '',
          :format => {
              :help => 'One address space in CIDR notation must be added.',
              :category => '2.Network Section',
              :order => 6,
              :filter => {'all' => {'visible' => 'express_route_enabled:eq:false'}}
          }

attribute 'subnet_address',
          :description => "Subnet Address Range",
          :default => '',
          :format => {
              :help => 'Many comma delimited subnet address ranges in CIDR notation may be added.',
              :category => '2.Network Section',
              :order => 7,
              :filter => {'all' => {'visible' => 'express_route_enabled:eq:false'}}
          }

attribute 'dns_ip',
          :description => "DNS Server(ip)",
          :default => "",
          :format => {
              :help => 'Optional- Fill this with public DNS server ip to use. if empty azure DNS servers will be used for public ip and pre-defined DNS server will be used for private ip.',
              :category => '2.Network Section',
              :order => 8,
              :filter => {'all' => {'visible' => 'express_route_enabled:eq:false'}}
          }


attribute 'sizemap',
  :description => "Sizes Map",
  :data_type => "hash",
  :default => '{ "XS":"Standard_A0","S":"Standard_A1","M":"Standard_A2","L":"Standard_A3","XL":"Standard_A4","XXL":"Standard_A6","3XL":"Standard_A7","4XL":"Standard_G1","S-CPU":"Standard_D2","M-CPU":"Standard_D3","L-CPU":"Standard_D4","S-IO":"Standard_DS1","M-IO":"Standard_DS2","L-IO":"Standard_DS3"}',
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
                "centos-6.6":"",
                "centos-6.4":"",
                "opensuse-13.1":"",
                "fedora-20":"",
                "fedora-19":""}',
  :format => {
    :help => 'Map of generic OS image types to provider specific 64-bit OS image types',
    :category => '3.Mappings',
    :order => 2
  }

  attribute 'ephemeral_disk_sizemap',
      :description => "Ephemeral Disk Sizes Map",
      :data_type => "hash",
      :default => '{ "XS":"0","S":"20","M":"17","L":"45","XL":"100","XXL":"100"}',
      :format => {
        :help => 'Map of generic datadisk sizes',
        :category => '3.Mappings',
        :order => 3
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
    :order => 3
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
      ['CentOS 7.0','centos-7.0'],['Ubuntu 14.04','ubuntu-14.04']]
  }
}

attribute 'initial_user',
  :description => "Initial UserName",
  :required => "required",
  :default => "azure",
  :format => {
    :help => 'Initial UserName to use for computes',
    :category => '4.Operating System',
    :order => 5
}

recipe "azure_subscription_status", "Check Azure Subscription Status"
