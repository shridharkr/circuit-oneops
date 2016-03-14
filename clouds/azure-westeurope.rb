name "azure-westeurope"
description "Microsoft Azure"
auth "F673C664-55DB-45EB-BEE7-4257A661538A"

image_map = '{
      "centos-7.0":"OpenLogic:CentOS:7.0:latest",
      "ubuntu-14.04":"canonical:ubuntuserver:14.04.3-LTS:14.04.201508050"
    }'

repo_map = '{
      "centos-7.0":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release",
      "ubuntu-14.04":""
}'

env_vars = '{ "rubygems":"https://rubygems.org/"}'

service "azure-westeurope",
  :cookbook => 'azure',
  :provides => { :service => 'compute' },
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :attributes => {
    :location => 'westeurope',
    :ostype => 'centos-7.0',
    :imagemap => image_map,
    :repo_map => repo_map,
    :env_vars => env_vars
  }
