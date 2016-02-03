name             "Haproxy"
description      "HA Proxy"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom' ]


attribute 'enable_stats_socket',
  :description => "Enable Stats Socket",
  :required => "required",
  :default => 'true',
  :format => {
    :help => 'Enable stats socket for monitoring',
    :category => '2.Stats',
    :form => { 'field' => 'checkbox' },
    :order => 1
  }

attribute 'stats_socket_location',
  :description => "Stats Socket Location",
  :required => "required",
  :default => '/var/lib/haproxy/stats',
  :format => {
    :help => 'Stats Socket Location',
    :category => '2.Stats',
    :order => 2
  }

attribute 'enable_stats_web',
  :description => "Enable Stats Web",
  :required => "required",
  :default => 'true',
  :format => {
    :help => 'Enable stats web monitoring',
    :category => '2.Stats',
    :form => { 'field' => 'checkbox' },
    :order => 3
  }

attribute 'stats_web_port',
  :description => "Stats Web Port",
  :required => "required",
  :default => '1936',
  :format => {
    :help => 'Stats Web port',
    :category => '2.Stats',
    :order => 4
  }
  
  
attribute 'lbmethod',
  :description => "LB Method",
  :required => "required",
  :default => "leastconn",
  :format => {
    :important => true,
    :help => 'Select the loadbalance method',
    :category => '1.Config',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['Least Connections','leastconn'],['RoundRobin','roundrobin']] }
  }

attribute 'lbmode',
  :description => "LB Mode",
  :required => "required",
  :default => "tcp",
  :format => {
    :important => true,
    :help => 'Select the loadbalance method',
    :category => '1.Config',
    :order => 2,
    :form => { 'field' => 'select', 'options_for_select' => [['TCP','tcp'],['HTTP','http']] }
  }
      
attribute 'listeners',
  :description => "Map of External to Internal Ports",
  :required => "required",  
  :default => "{}",
  :data_type => "hash",
  :format => {
    :important => true,
    :help => 'Map of External to Internal Ports - uses RequiresCompute payload for internal server list. Make sure they are not the same.',
    :category => '1.Config',
    :order => 3
  }   
    
attribute 'timeout_connect',
  :description => "Timeout Connect",
  :required => "required",
  :default => "500s",
  :format => {
    :help => 'Timeout Connect',
    :category => '1.Config',
    :order => 4
  }

attribute 'timeout_client',
  :description => "Timeout Client",
  :required => "required",
  :default => "5000s",
  :format => {
    :help => 'Timeout Client',
    :category => '1.Config',
    :order => 5
  }

attribute 'timeout_server',
  :description => "Timeout Server",
  :required => "required",
  :default => "1h",
  :format => {
    :help => 'Timeout Server',
    :category => '1.Config',
    :order => 6
  }

attribute 'maxconn_defaults',
  :description => "Max Connections Defaults",
  :required => "required",
  :default => "32000",
  :format => {
    :help => 'Max Connections Global',
    :category => '1.Config',
    :order => 7
  }

attribute 'maxconn_server',
  :description => "Max Connections Per Server",
  :required => "required",
  :default => "1500",
  :format => {
    :help => 'Max Connections Per Server',
    :category => '1.Config',
    :order => 8
  } 
  
attribute 'retries',
  :description => "Retries",
  :required => "required",
  :default => "3",
  :format => {
    :help => 'Retries',
    :category => '1.Config',
    :order => 9
  }         

attribute 'options',
  :description => "Options",
  :required => "required",
  :default => '["dontlognull","redispatch"]',
  :data_type => "array",
  :format => {
    :help => 'Options',
    :category => '1.Config',
    :order => 10
  }         
  
             
    
attribute 'override_config',
  :description => "Override Config Content",
  :data_type => "text",
  :format => {
    :help => 'Will use this config or if empty generate config based on members',
    :category => '1.Config',
    :order => 20
  }
  
recipe "status", "Haproxy Status"
recipe "start", "Start Haproxy"
recipe "stop", "Stop Haproxy"
recipe "restart", "Restart Haproxy"
recipe "repair", "Repair Haproxy"
