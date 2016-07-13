include_pack 'docker'

name         'kubernetes'
description  'Kubernetes'
type         'Platform'
category     'Infrastructure Service'


resource 'secgroup',
  :attributes => {
      :inbound => '[
        "22 22 tcp 0.0.0.0/0", 
        "80 80 tcp 0.0.0.0/0",
        "8472 8472 udp 0.0.0.0/0",
        "8285 8285 udp 0.0.0.0/0",
        "53 53 tcp 0.0.0.0/0",
        "53 53 udp 0.0.0.0/0",
        "2181 2181 tcp 0.0.0.0/0",
        "3888 3888 tcp 0.0.0.0/0",
        "8080 8080 tcp 0.0.0.0/0", 
        "2888 2888 tcp 0.0.0.0/0",
        "10053 10053 tcp 0.0.0.0/0"
      ]'
  }

resource 'docker_engine',
         :attributes => {
             :version => '1.11.2',
             :root => '$OO_LOCAL{docker-root}',
             :repo => '$OO_LOCAL{docker-repo}',
             :network => 'flannel',
             :network_cidr => '11.11.0.0/16',
             :network_subnet => '11.11.{INSTANCE_INDEX}.1/24',           
         } 
 
resource 'secgroup-master',
  :cookbook => 'oneops.1.secgroup',
  :design => true,
  :attributes => {
      :inbound => '["22 22 tcp 0.0.0.0/0", "8080 8080 tcp 0.0.0.0/0", "2379 2380 tcp 0.0.0.0/0" ]'
  },
  :requires => {
      :constraint => '1..1',
      :services => 'compute'
  }

resource 'compute-master',
  :cookbook => "oneops.1.compute",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute,dns" },
  :attributes => { "size"    => "S"
                 },
  :monitors => {
      'ssh' =>  { :description => 'SSH Port',
                  :chart => {'min'=>0},
                  :cmd => 'check_port',
                  :cmd_line => '/opt/nagios/libexec/check_port.sh',
                  :heartbeat => true,
                  :duration => 5,
                  :metrics =>  {
                    'up'  => metric( :unit => '%', :description => 'Up %')
                  },
                  :thresholds => {
                  },
                }
  },
  :payloads => {
    'os' => {
      'description' => 'os',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.oneops.1.Compute",
         "relations": [
           { "returnObject": true,
             "returnRelation": false,
             "relationName": "manifest.DependsOn",
             "direction": "to",
             "targetClassName": "manifest.oneops.1.Os"
           }
         ]
      }'
    }
  }

resource 'os',
  :attributes => {:ostype => 'centos-7.2'}
    
resource 'os-master',
  :cookbook => 'oneops.1.os',
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute,dns,*ntp" },
  :attributes => { "ostype"   => "centos-7.2",
                   "dhclient" => 'true'
                 },
:monitors => {
    'cpu' =>  { :description => 'CPU',
                :source => '',
                :chart => {'min'=>0,'max'=>100,'unit'=>'Percent'},
                :cmd => 'check_local_cpu!10!5',
                :cmd_line => '/opt/nagios/libexec/check_cpu.sh $ARG1$ $ARG2$',
                :metrics =>  {
                  'CpuUser'   => metric( :unit => '%', :description => 'User %'),
                  'CpuNice'   => metric( :unit => '%', :description => 'Nice %'),
                  'CpuSystem' => metric( :unit => '%', :description => 'System %'),
                  'CpuSteal'  => metric( :unit => '%', :description => 'Steal %'),
                  'CpuIowait' => metric( :unit => '%', :description => 'IO Wait %'),
                  'CpuIdle'   => metric( :unit => '%', :description => 'Idle %', :display => false)
                },
                :thresholds => {
                   'HighCpuPeak' => threshold('5m','avg','CpuIdle',trigger('<=',10,5,1),reset('>',20,5,1)),
                   'HighCpuUtil' => threshold('1h','avg','CpuIdle',trigger('<=',20,60,1),reset('>',30,60,1))
                }
              },
    'load' =>  { :description => 'Load',
                :chart => {'min'=>0},
                :cmd => 'check_local_load!5.0,4.0,3.0!10.0,6.0,4.0',
                :cmd_line => '/opt/nagios/libexec/check_load -w $ARG1$ -c $ARG2$',
                :duration => 5,
                :metrics =>  {
                  'load1'  => metric( :unit => '', :description => 'Load 1min Average'),
                  'load5'  => metric( :unit => '', :description => 'Load 5min Average'),
                  'load15' => metric( :unit => '', :description => 'Load 15min Average'),
                },
                :thresholds => {
                },
              },
    'disk' =>  {'description' => 'Disk',
                'chart' => {'min'=>0,'unit'=> '%'},
                'cmd' => 'check_disk_use!/',
                'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                               'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                :thresholds => {
                  'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                  'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
                },
              },
    'mem' =>  { 'description' => 'Memory',
                'chart' => {'min'=>0,'unit'=>'KB'},
                'cmd' => 'check_local_mem!90!95',
                'cmd_line' => '/opt/nagios/libexec/check_mem.pl -Cu -w $ARG1$ -c $ARG2$',
                'metrics' =>  {
                  'total'  => metric( :unit => 'KB', :description => 'Total Memory'),
                  'used'   => metric( :unit => 'KB', :description => 'Used Memory'),
                  'free'   => metric( :unit => 'KB', :description => 'Free Memory'),
                  'caches' => metric( :unit => 'KB', :description => 'Cache Memory')
                },
                :thresholds => {
                },
            },
    'network' => {:description => 'Network',
                     :source => '',
                     :chart => {'min' => 0, 'unit' => ''},
                     :cmd => 'check_network_bandwidth',
                     :cmd_line => '/opt/nagios/libexec/check_network_bandwidth.sh',
                     :metrics => {
                       'rx_bytes' => metric(:unit => 'bytes', :description => 'RX Bytes', :dstype => 'DERIVE'),
                       'tx_bytes' => metric(:unit => 'bytes', :description => 'TX Bytes', :dstype => 'DERIVE')
                }
           }
  },
  :payloads => {
  'linksto' => {
    'description' => 'LinksTo',
    'definition' => '{
      "returnObject": false,
      "returnRelation": false,
      "relationName": "base.RealizedAs",
      "direction": "to",
      "relations": [
        { "returnObject": false,
          "returnRelation": false,
          "relationName": "manifest.Requires",
          "direction": "to",
          "targetClassName": "manifest.Platform",
          "relations": [
            { "returnObject": false,
              "returnRelation": false,
              "relationName": "manifest.LinksTo",
              "direction": "from",
              "targetClassName": "manifest.Platform",
              "relations": [
                { "returnObject": true,
                  "returnRelation": false,
                  "relationName": "manifest.Entrypoint",
                  "direction": "from"
                }
              ]
            }
          ]
        }
      ]
    }'
  }
}    


resource 'etcd-master',
  :cookbook => 'oneops.1.etcd',
  :requires => { "constraint" => "1..1", "services" => "*mirror" },
  :design => true,
  :payloads => {
'RequiresComputes' => {
    'description' => 'computes',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Etcd",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.DependsOn",
           "direction": "from",
           "targetClassName": "manifest.oneops.1.Compute",
           "relations": [
             { "returnObject": true,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "from",
               "targetClassName": "bom.oneops.1.Compute"
             }
           ]
         }
       ]
    }'
  }
 }
  
resource 'kubernetes-master',
  :cookbook => 'oneops.1.kubernetes',
  :requires => { "constraint" => "1..1", "services" => "*mirror" },
  :design => true,
  :payloads => {
  'master-computes' => {
    'description' => 'master-computes',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Kubernetes",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.Requires",
               "targetCiName": "kubernetes-master",
               "direction": "from",
               "targetClassName": "manifest.oneops.1.Kubernetes",
              "relations": [
                { "returnObject": false,
                  "returnRelation": false,
                  "relationName": "manifest.ManagedVia",
                  "direction": "from",
                  "targetClassName": "manifest.oneops.1.Compute",
                  "relations": [
                      { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.RealizedAs",
                        "direction": "from",
                        "targetClassName": "bom.oneops.1.Compute"
                      }
                    ]
  
                 }              
               ]
  
             }
           ]
         }
       ]
    }'
  },
    'worker-computes' => {
      'description' => 'computes',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.oneops.1.Kubernetes",
         "relations": [
           { "returnObject": false,
             "returnRelation": false,
             "relationName": "manifest.Requires",
             "direction": "to",
             "targetClassName": "manifest.Platform",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationName": "manifest.Requires",
                 "targetCiName": "kubernetes-worker",
                 "direction": "from",
                 "targetClassName": "manifest.oneops.1.Kubernetes",
                "relations": [
                  { "returnObject": false,
                    "returnRelation": false,
                    "relationName": "manifest.DependsOn",
                    "direction": "from",
                    "targetClassName": "manifest.oneops.1.Compute",
                    "relations": [
                        { "returnObject": true,
                          "returnRelation": false,
                          "relationName": "base.RealizedAs",
                          "direction": "from",
                          "targetClassName": "bom.oneops.1.Compute"
                        }
                      ]
    
                   }              
                 ]
    
               }
             ]
           }
         ]
      }'
    },
    'manifest-docker' => {
      'description' => 'manifest-docker',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.oneops.1.Kubernetes",
         "relations": [
           { "returnObject": false,
             "returnRelation": false,
             "relationName": "manifest.Requires",
             "direction": "to",
             "targetClassName": "manifest.Platform",
             "relations": [
               { "returnObject": true,
                 "returnRelation": false,
                 "relationName": "manifest.Requires",
                 "direction": "from",
                 "targetClassName": "manifest.oneops.1.Docker_engine"    
               }
             ]
           }
         ]
      }'
    }          
  }


resource 'kubernetes-worker',
  :cookbook => 'oneops.1.kubernetes',
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "*mirror" },
  :payloads => {
'master-computes' => {
  'description' => 'master-computes',
  'definition' => '{
     "returnObject": false,
     "returnRelation": false,
     "relationName": "base.RealizedAs",
     "direction": "to",
     "targetClassName": "manifest.oneops.1.Kubernetes",
     "relations": [
       { "returnObject": false,
         "returnRelation": false,
         "relationName": "manifest.Requires",
         "direction": "to",
         "targetClassName": "manifest.Platform",
         "relations": [
           { "returnObject": false,
             "returnRelation": false,
             "relationName": "manifest.Requires",
             "targetCiName": "kubernetes-master",
             "direction": "from",
             "targetClassName": "manifest.oneops.1.Kubernetes",
            "relations": [
              { "returnObject": false,
                "returnRelation": false,
                "relationName": "manifest.ManagedVia",
                "direction": "from",
                "targetClassName": "manifest.oneops.1.Compute",
                "relations": [
                    { "returnObject": true,
                      "returnRelation": false,
                      "relationName": "base.RealizedAs",
                      "direction": "from",
                      "targetClassName": "bom.oneops.1.Compute"
                    }
                  ]

               }              
             ]

           }
         ]
       }
     ]
  }'
},
  'worker-computes' => {
    'description' => 'computes',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Kubernetes",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.Requires",
               "targetCiName": "kubernetes-worker",
               "direction": "from",
               "targetClassName": "manifest.oneops.1.Kubernetes",
              "relations": [
                { "returnObject": false,
                  "returnRelation": false,
                  "relationName": "manifest.DependsOn",
                  "direction": "from",
                  "targetClassName": "manifest.oneops.1.Compute",
                  "relations": [
                      { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.RealizedAs",
                        "direction": "from",
                        "targetClassName": "bom.oneops.1.Compute"
                      }
                    ]
  
                 }              
               ]
  
             }
           ]
         }
       ]
    }'
  }  
}
  
  
resource "lb-master-certificate",
  :cookbook => "oneops.1.certificate",
  :design => true,
  :requires => { "constraint" => "0..1" },
  :attributes => {}

resource "lb-master",
  :except => [ 'single' ],
  :design => true,
  :cookbook => "oneops.1.lb",
  :requires => { "constraint" => "1..1", "services" => "compute,lb,dns" },
  :attributes => {
    "listeners"     => '["http 8080 http 8080"]',
    "ecv_map"       => '{"8080":"GET /api/"}'
  },
  :payloads => {
  'primaryactiveclouds' => {
      'description' => 'primaryactiveclouds',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.Lb",
         "relations": [
           { "returnObject": false,
             "returnRelation": false,
             "relationName": "manifest.Requires",
             "direction": "to",
             "targetClassName": "manifest.Platform",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"},
                                  {"attributeName":"adminstatus", "condition":"neq", "avalue":"offline"}],
                 "relationName": "base.Consumes",
                 "direction": "from",
                 "targetClassName": "account.Cloud",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"lb"}],
                     "relationName": "base.Provides",
                     "direction": "from",
                     "targetClassName": "cloud.service.Netscaler"
                   }
                 ]
               }
             ]
           }
         ]
      }'
    }
  }

resource "fqdn-master",
  :cookbook => "oneops.1.fqdn",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute,dns,*gdns,lb" },
  :attributes => { "aliases" => '["master"]' },
  :payloads => {
'environment' => {
    'description' => 'Environment',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Fqdn",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": true,
               "returnRelation": false,
               "relationName": "manifest.ComposedOf",
               "direction": "to",
               "targetClassName": "manifest.Environment"
             }
           ]
         }
       ]
    }'
  },
'activeclouds' => {
    'description' => 'activeclouds',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Fqdn",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"},
                                {"attributeName":"adminstatus", "condition":"eq", "avalue":"active"}],
               "relationName": "base.Consumes",
               "direction": "from",
               "targetClassName": "account.Cloud",
               "relations": [
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "relationName": "base.Provides",
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Netscaler"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "direction": "from",
                   "targetClassName": "cloud.service.Netscaler"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Route53"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Designate"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Rackspacedns"
                 },    
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "relationName": "base.Provides",
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Azuretrafficmanager"
                 }
               ]
             }
           ]
         }
       ]
    }'
  },
'organization' => {
    'description' => 'Organization',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Fqdn",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.ComposedOf",
               "direction": "to",
               "targetClassName": "manifest.Environment",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.RealizedIn",
                   "direction": "to",
                   "targetClassName": "account.Assembly",
                   "relations": [
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Manages",
                       "direction": "to",
                       "targetClassName": "account.Organization"
                     }
                   ]
                 }
               ]
             }
           ]
         }
       ]
    }'
  },
 'lb' => {
    'description' => 'all loadbalancers',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "bom.DependsOn",
       "direction": "from",
       "targetClassName": "bom.oneops.1.Lb",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "base.RealizedAs",
           "direction": "to",
           "targetClassName": "manifest.oneops.1.Lb",
           "relations": [
             { "returnObject": true,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "from",
               "targetClassName": "bom.oneops.1.Lb"
             }
           ]
         }
       ]
    }'
  },
   'remotedns' => {
       'description' => 'Other clouds dns services',
       'definition' => '{
           "returnObject": false,
           "returnRelation": false,
           "relationName": "base.RealizedAs",
           "direction": "to",
           "targetClassName": "manifest.oneops.1.Fqdn",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.Requires",
               "direction": "to",
               "targetClassName": "manifest.Platform",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.Consumes",
                   "direction": "from",
                   "targetClassName": "account.Cloud",
                   "relations": [
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.Infoblox"
                     },
                   { "returnObject": true,
                      "returnRelation": false,
                      "relationName": "base.Provides",
                      "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                      "direction": "from",
                      "targetClassName": "cloud.service.oneops.1.Route53"
                    },
                   { "returnObject": true,
                      "returnRelation": false,
                      "relationName": "base.Provides",
                      "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                      "direction": "from",
                      "targetClassName": "cloud.service.oneops.1.Designate"
                    },
                   { "returnObject": true,
                      "returnRelation": false,
                      "relationName": "base.Provides",
                      "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                      "direction": "from",
                      "targetClassName": "cloud.service.oneops.1.Rackspacedns"
                    },
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.oneops.1.Infoblox"
                     }
                   ]
                 }
               ]
             }
           ]
      }'
    },
   'remotegdns' => {
       'description' => 'Other clouds gdns services',
       'definition' => '{
           "returnObject": false,
           "returnRelation": false,
           "relationName": "base.RealizedAs",
           "direction": "to",
           "targetClassName": "manifest.oneops.1.Fqdn",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.Requires",
               "direction": "to",
               "targetClassName": "manifest.Platform",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.Consumes",
                   "direction": "from",
                   "targetClassName": "account.Cloud",
                   "relations": [
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.oneops.1.Netscaler"
                     },
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.Netscaler"
                     },       
                     { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.Provides",
                        "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                        "direction": "from",
                        "targetClassName": "cloud.service.oneops.1.Route53"
                      },
                     { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.Provides",
                        "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                        "direction": "from",
                        "targetClassName": "cloud.service.oneops.1.Designate"
                      },
                     { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.Provides",
                        "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                        "direction": "from",
                        "targetClassName": "cloud.service.oneops.1.Rackspacedns"
                      },
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.oneops.1.Azuretrafficmanager"
                     }
                   ]
                 }
               ]
             }
           ]
      }'
    }
  }
  
  
resource 'user-master',
  :cookbook => "oneops.1.user",
  :design => true,
  :requires => { "constraint" => "0..*" }


#    
# relations
#

[ 'lb-master' ].each do |from|
  relation "#{from}::depends_on::compute-master",
    :only => [ 'redundant' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute-master',
    :attributes    => { "propagate_to" => 'both', "flex" => true, "current" =>3, "min" => 1, "max" => 5}
end

# -d name due to pack sync logic uses a map keyed by that name - it doesnt get put into cms
[ 'lb-master' ].each do |from|
  relation "#{from}::depends_on::compute-d",
    :only => [ '_default' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute-master',
    :attributes    => { "flex" => false }
end

       
[ 'lb-master' ].each do |from|
  relation "#{from}::depends_on::lb-master-certificate",
    :except => [ 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource => 'lb-certificate',
    :attributes => { "propagate_to" => 'from', "flex" => false, "min" => 0, "max" => 1 }
end


# depends_on

[ 'lb' ].each do |from|
  relation "#{from}::depends_on::compute",
    :only => [ 'redundant' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'both', "flex" => true, "current" =>2, "min" => 1, "max" => 256}
end


[ 'fqdn-master' ].each do |from|
  relation "#{from}::depends_on::lb-master",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'lb-master',
    :attributes    => { "propagate_to" => 'both', "flex" => false }
end    

# needed for kube-proxy --master arg (only takes 1 ip) and a name/domain will not work 
# more notes in the worker recipe
[ 'kubernetes-worker' ].each do |from|
  relation "#{from}::depends_on::lb-master",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'lb-master',
    :attributes    => { "propagate_to" => 'both', "flex" => false, "converge" => true }
end   

[ 'fqdn-master' ].each do |from|
  relation "#{from}::depends_on::compute-master",
    :only => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute-master',
    :attributes    => { "propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 }
end  


[ { :from => 'compute-master',     :to => 'secgroup-master' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "converge" => true, "min" => 1, "max" => 1 }
end

[ { :from => 'user-master',      :to => 'os-master' },
  { :from => 'etcd-master',      :to => 'compute-master' },
  { :from => 'etcd-master',      :to => 'os-master' },        
  { :from => 'kubernetes-master',:to => 'etcd-master' },
  { :from => 'os-master',        :to => 'compute-master' },
  { :from => 'kubernetes-worker',:to => 'docker_engine' },
  { :from => 'kubernetes-worker',:to => 'compute' }
    ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { } 
end


# managed_via
[ 'os-master','etcd-master','kubernetes-master','user-master' ].each do |from|
  relation "#{from}::managed_via::compute-master",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute-master',
    :attributes    => { } 
end

[ 'kubernetes-worker'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end


# secured_by
[ 'compute-master'].each do |from|
  relation "#{from}::secured_by::sshkeys",
    :except => [ '_default' ],
    :relation_name => 'SecuredBy',
    :from_resource => from,
    :to_resource   => 'sshkeys',
    :attributes    => { }
end


