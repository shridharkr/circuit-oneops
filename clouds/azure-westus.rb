name "azure-westus"
description "Microsoft Azure"
auth "310916F4-DCDA-416C-A705-216FA81B9132"

image_map = '{
      "centos-7.0":"OpenLogic:CentOS:7.0:latest",
      "ubuntu-14.04":"canonical:ubuntuserver:14.04.3-LTS:14.04.201508050"
    }'

repo_map = '{
      "centos-7.0":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++",
      "ubuntu-14.04":""
}'

env_vars = '{ "rubygems":"https://rubygems.org/"}'

service "azure-westus",
  :cookbook => 'azure',
  :provides => { :service => 'compute' },
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :attributes => {
    :location => 'westus',
    :ostype => 'centos-7.0',
    :imagemap => image_map,
    :repo_map => repo_map,
    :env_vars => env_vars
  }
