name "swarm"
description "Docker Swarm"
auth ""
is_location "true"

service "swarm",
  :cookbook => 'swarm',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'), 
  :provides => { :service => 'container' },
  :attributes => {
  }
