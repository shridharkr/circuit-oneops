name "softlayer"
description "SoftLayer"
auth "softlayersecretkey"
is_location "true"

image_map = '{
}'

repo_map = '{
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
