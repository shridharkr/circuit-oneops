name              'Kubernetes'
maintainer        'OneOps'
license           'Apache 2.0'
description       'Configures and installs Kubernetes'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           '0.0.1'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

    
attribute 'version',
  :description => "version",
  :default => "1.2.4",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Version',
    :category => '1.Shared',
    :order => 1
  }        
  
attribute 'network',
  :description => "Network overlay",
  :default => "openvswitch",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Network overlay - flannel or openvswitch',
    :category => '1.Shared',
    :order => 1
  }        

attribute 'api_port',
  :description => "api port",
  :default => "8080",
  :required => "required",
  :format => {
    :important => true,
    :help => 'API Port',
    :category => '1.Master',
    :order => 1
  }

attribute 'service_addresses',
  :description => "service address cidr",
  :default => "10.254.0.0/16",
  :required => "required",
  :format => {
    :important => true,
    :help => 'service address cidr',
    :category => '1.Master',
    :order => 1
  }

attribute 'controller_manager_args',
  :description => "Controller Manager Args",
  :data_type => "hash",
  :default => '{}',
  :required => "required",
  :format => {
    :important => true,
    :help => 'Controller Manager Args',
    :category => '1.Master',
    :order => 1
  }
  
    
attribute 'scheduler_args',
  :description => "Scheduler Args",
  :data_type => "hash",
  :default => '{}',
  :required => "required",
  :format => {
    :help => 'Scheduler Args',
    :category => '1.Master',
    :order => 1
  }
    
attribute 'kubelet_port',
  :description => "kubelet bind port",
  :default => "10250",
  :required => "required",
  :format => {
    :help => 'Minon Kublet',
    :category => '1.Worker',
    :order => 1
  }
  
attribute 'kubelet_args',
  :description => "kubelet args",
  :data_type => "hash",
  :default => '{}',
  :required => "required",
  :format => {
    :help => 'Minon Args',
    :category => '1.Worker',
    :order => 1
  }  

attribute 'proxy_args',
  :description => "proxy args",
  :data_type => "hash",
  :default => '{}',
  :required => "required",
  :format => {
    :help => 'Proxy Args',
    :category => '1.Worker',
    :order => 1
  }  

attribute 'interface',
  :description => "Interface",
  :default => "eth0",
  :required => "required",
  :format => {
    :help => 'Interface',
    :category => '1.Worker',
    :order => 1
  }    
