name "rackspace-dfw"
description "Rackspace DFW (Dallas)"
auth "rackspacesecretkey"
is_location "true"

image_map = '{
      "centos-6.7":"21612eaf-a350-4047-b06f-6bb8a8a7bd99",
      "centos-7.0":"9d29f10e-4fc2-4556-8d25-532d1784329a",
      "ubuntu-14.04":"09de0a66-3156-48b4-90a5-1cf25a905207",
      "ubuntu-13.04":"4b54f5a0-137f-4751-8e7c-fe707185e531",
      "ubuntu-12.10":"d45ed9c5-d6fc-4c9d-89ea-1b3ae1c83999",
      "ubuntu-12.04":"80fbcb55-b206-41f9-9bc2-2dd7aac6c061",
      "ubuntu-10.04":"aab63bcf-89aa-440f-b0c7-c7a1c611914",
      "redhat-6.4":"c6e2fed0-75bf-420d-a744-7cfc75a1889e",
      "redhat-6.3":"",
      "redhat-6.2":"",
      "redhat-5.9":"da3a46dc-ea96-44bb-8f6b-37d65f1d4e23",
      "fedora-19":"6fa6747b-764b-4045-b3b2-0c26cb6c4347",
      "fedora-18":"b37fd1ad-6811-4714-941f-17a522b59af4"
}'

repo_map = '{
      "centos-6.3":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm",
      "centos-6.4":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
}'

service "rackspace-dfw",
  :description => 'Compute-as-a-Service Rackspace DFW',
  :cookbook => 'rackspace',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),  
  :provides => { :service => 'compute' },
  :attributes => {
    :tenant => "",
    :username => "",
    :region => "DFW",
    :subnet => "",
    :imagemap => image_map,
    :repo_map => repo_map
  }

service "rackspace-dfw-lb",
  :description => 'Lb-as-a-Service Rackspace DFW',
  :cookbook => 'rackspace',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),  
  :provides => { :service => 'lb' },
  :attributes => {
    :tenant => "",
    :username => "",
    :api_key => "",
    :region => "DFW"
  }

service "rackspace-dns",
  :description => 'DNS-as-a-Service Rackspace',
  :cookbook => 'rackspacedns',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),  
  :provides => { :service => 'dns' },
  :attributes => {
    :username => "",
    :api_key => ""
  }

service "rackspace-gdns",
  :description => 'GDNS-as-a-Service Rackspace',
  :cookbook => 'rackspacedns',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),  
  :provides => { :service => 'gdns' },
  :attributes => {
    :username => "",
    :api_key => ""
  }
  
