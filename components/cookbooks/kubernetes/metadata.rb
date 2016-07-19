name              'Kubernetes'
maintainer        'OneOps'
license           'Apache 2.0'
description       'Configures and installs Kubernetes'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           '0.0.1'


grouping 'default',
  :access => "global",
  :packages => [ 'base']

grouping 'cluster',
  :access => "global",
  :packages => [ 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

grouping 'service',
  :access => "global",
  :packages => [ 'service.kubernetes', 'mgmt.cloud.service', 'cloud.service' ]

# attrs for cloud service
attribute 'endpoint',
  :grouping => 'service',
  :description => "endpoint",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Endpoint of kubernetes cluster',
    :category => '1.General',
    :order => 1
  }    

attribute 'namespace',
  :grouping => 'service',
  :description => "namespace",
  :default => "default",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Namespace',
    :category => '1.General',
    :order => 2
  }    

attribute 'username',
  :grouping => 'service',
  :description => "username",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Username',
    :category => '1.General',
    :order => 3
  }      

attribute 'password',
  :grouping => 'service',
  :description => "password",
  :encrypted => true, 
  :required => "required",
  :format => {
    :help => 'Password',
    :category => '1.General',
    :order => 4
  }      
        
        
# attrs for cluster
attribute 'version',
  :grouping => 'cluster',
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
  :grouping => 'cluster',
  :description => "Network overlay",
  :default => "flannel",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Network overlay - flannel or openvswitch',
    :category => '1.Shared',
    :order => 1
  }        

attribute 'api_port',
  :grouping => 'cluster',
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
  :grouping => 'cluster',
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
  :grouping => 'cluster',
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
  :grouping => 'cluster',
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
  :grouping => 'cluster',
  :description => "kubelet bind port",
  :default => "10250",
  :required => "required",
  :format => {
    :help => 'Minon Kublet',
    :category => '1.Worker',
    :order => 1
  }
  
attribute 'kubelet_args',
  :grouping => 'cluster',
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
  :grouping => 'cluster',
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
  :grouping => 'cluster',
  :description => "Interface",
  :default => "eth0",
  :required => "required",
  :format => {
    :help => 'Interface',
    :category => '1.Worker',
    :order => 1
  }    
