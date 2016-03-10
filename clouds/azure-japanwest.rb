name "azure-japanwest"
description "Microsoft Azure"
auth "3ACFA66E-1DA4-4A04-B3C1-48A1A4761C89"

image_map = '{
      "centos-7.0":"OpenLogic:CentOS:7.0:latest",
      "ubuntu-14.04":"canonical:ubuntuserver:14.04.3-LTS:14.04.201508050"
    }'

repo_map = '{
      "centos-7.0":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release",
      "ubuntu-14.04":""
}'

env_vars = '{ "rubygems":"https://rubygems.org/"}'

service "azure-japanwest",
  :cookbook => 'azure',
  :provides => { :service => 'compute' },
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :attributes => {
    :location => 'japanwest',
    :ostype => 'centos-7.0',
    :imagemap => image_map,
    :repo_map => repo_map,
    :env_vars => env_vars
  }
