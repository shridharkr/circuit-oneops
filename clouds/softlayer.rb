name "softlayer"
description "SoftLayer"
auth "softlayersecretkey"
is_location "true"

image_map = '{
}'

repo_map = '{
      "centos-7.0":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++",
      "ubuntu-14.04":""
}'

service "softlayer",
  :description => 'Softlayer VSI',
  :cookbook => 'softlayer',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),  
  :provides => { :service => 'compute' },
  :attributes => {
    :username => "",
    :imagemap => image_map,
    :repo_map => repo_map
  }
