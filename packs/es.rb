include_pack 'genericlb'

name         'es'
description  'ElasticSearch With LB'
type         'Platform'
category     'Search Engine'

# Overriding the default compute
resource 'compute',
         :attributes => {
           'ostype' => 'default-cloud',
           'size' => 'M'
         }

resource 'user-app',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => {'constraint' => '1..1'},
         :attributes => {
             'username' => 'app',
             'description' => 'App-User',
             'home_directory' => '/app/',
             'system_account' => true,
             'sudoer' => true
         }

# overwrite volume and filesystem from generic_ring with new mount point
resource 'volume',
         :requires => {'constraint' => '1..1', 'services' => 'compute'},
         :attributes => {'mount_point' => '/data',
                         'size' => '100%FREE',
                         'device' => '',
                         'fstype' => 'ext4',
                         'options' => ''
         }

resource 'java',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '0..1',
             :services => '*mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {}


resource 'elasticsearch',
         :cookbook => 'oneops.1.es',
         :design => true,
         :requires => {'constraint' => '1..*', 'services' => 'mirror'},
         :attributes => {
             'version' => '1.1.1'
         },
         :monitors => {
             'Log' => {:description => 'Log',
                       :source => '',
                       :chart => {'min' => 0, 'unit' => ''},
                       :cmd => 'check_logfiles!logelasticsearch!:::node.workorder.rfcCi.ciAttributes.log_dir:::/:::node.workorder.rfcCi.ciAttributes.cluster_name:::.log!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                       :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                       :cmd_options => {
                           'warningpattern' => 'WARNING',
                           'criticalpattern' => 'CRITICAL'
                       },
                       :metrics => {
                           'logelasticsearch_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                           'logelasticsearch_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                           'logelasticsearch_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                           'logelasticsearch_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                       },
                       :thresholds => {
                         'CriticalLogException' => threshold('1m', 'avg', 'logelasticsearch_criticals', trigger('>=', 1, 5, 1), reset('<', 1, 15, 1)),
                       }
             },
             'status' => {
                 :description => 'Status',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_es_node_stats!:::node.workorder.rfcCi.ciAttributes.http_port:::',
                 :cmd_line => '/opt/nagios/libexec/check_es_node_stats.rb $ARG1$',
                 :metrics => {
                     'status' => metric(:unit => '', :description => 'status', :dstype => 'GAUGE'),
                 },
                 :thresholds => {
                 }

             },
             'indexed_doc_count' => {
                 :description => 'Indexed_doc_count',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_es_node_stats!:::node.workorder.rfcCi.ciAttributes.http_port:::',
                 :cmd_line => '/opt/nagios/libexec/check_es_node_stats.rb $ARG1$',
                 :metrics => {
                     'indexed_doc_count' => metric(:unit => '', :description => 'doc_count', :dstype => 'DERIVE'),
                 },
                 :thresholds => {
                 }

             },
             'search_rate' => {
                 :description => 'Search_rate',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_es_node_stats!:::node.workorder.rfcCi.ciAttributes.http_port:::',
                 :cmd_line => '/opt/nagios/libexec/check_es_node_stats.rb $ARG1$',
                 :metrics => {
                     'search_rate' => metric(:unit => '', :description => 'search_rate', :dstype => 'GAUGE'),
                 },
                 :thresholds => {
                 }

             },
             'filter_cache_evictions' => {
                 :description => 'Filter_cache_evictions',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_es_node_stats!:::node.workorder.rfcCi.ciAttributes.http_port:::',
                 :cmd_line => '/opt/nagios/libexec/check_es_node_stats.rb $ARG1$',
                 :metrics => {
                     'filter_cache_evictions' => metric(:unit => '', :description => 'filter_cache_evictions', :dstype => 'GAUGE'),
                 },
                 :thresholds => {
                 }

             },
             'heap_used_percent' => {
                 :description => 'Heap_used_percent',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_es_node_stats!:::node.workorder.rfcCi.ciAttributes.http_port:::',
                 :cmd_line => '/opt/nagios/libexec/check_es_node_stats.rb $ARG1$',
                 :metrics => {
                     'heap_used_percent' => metric(:unit => '%', :description => 'Heap used percent', :dstype => 'GAUGE'),
                 },
                 :thresholds => {
                 }

             },
             'gc_old_collections' => {
                 :description => 'Gc_old_collections',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_es_node_stats!:::node.workorder.rfcCi.ciAttributes.http_port:::',
                 :cmd_line => '/opt/nagios/libexec/check_es_node_stats.rb $ARG1$',
                 :metrics => {
                     'gc_old_collections' => metric(:unit => '', :description => 'gc_old_collections', :dstype => 'GUAGE'),
                 },
                 :thresholds => {
                 }

             },
             'index_rejections' => {
                 :description => 'Index_rejections',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_es_node_stats!:::node.workorder.rfcCi.ciAttributes.http_port:::',
                 :cmd_line => '/opt/nagios/libexec/check_es_node_stats.rb $ARG1$',
                 :metrics => {
                     'index_rejections' => metric(:unit => '', :description => 'index_rejections', :dstype => 'GAUGE'),
                 },
                 :thresholds => {
                 }

             },
             'search_rejections' => {
                 :description => 'Search_rejections',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_es_node_stats!:::node.workorder.rfcCi.ciAttributes.http_port:::',
                 :cmd_line => '/opt/nagios/libexec/check_es_node_stats.rb $ARG1$',
                 :metrics => {
                     'search_rejections' => metric(:unit => '', :description => 'search_rejections', :dstype => 'GAUGE'),
                 },
                 :thresholds => {
                 }

             },
             'disk_reads' => {
                 :description => 'Disk_reads',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_es_node_stats!:::node.workorder.rfcCi.ciAttributes.http_port:::',
                 :cmd_line => '/opt/nagios/libexec/check_es_node_stats.rb $ARG1$',
                 :metrics => {
                     'disk_reads' => metric(:unit => '', :description => 'disk_reads', :dstype => 'GAUGE'),
                 },
                 :thresholds => {
                 }

             },
             'disk_writes' => {
                 :description => 'Disk_writes',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_es_node_stats!:::node.workorder.rfcCi.ciAttributes.http_port:::',
                 :cmd_line => '/opt/nagios/libexec/check_es_node_stats.rb $ARG1$',
                 :metrics => {
                     'disk_writes' => metric(:unit => '', :description => 'disk_writes', :dstype => 'GAUGE'),
                 },
                 :thresholds => {
                 }

             }
             
         }
         
resource 'index',
         :cookbook => 'oneops.1.index',
         :design => true,
         :requires => {'constraint' => '0..*','services' => 'compute'},
         :attributes => {
         }  
         
resource 'logstash',
         :cookbook => 'oneops.1.logstash',
         :design => true,
         :requires => {'constraint' => '0..1', 'services' => 'mirror'},
         :attributes => {
         },
         :monitors => {
             'logstashprocess' => {:description => 'LogstashProcess',
                           :source => '',
                           :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                           :cmd => 'check_process!logstash!false!logstash/runner.rb',
                           :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                           :metrics => {
                               'up' => metric(:unit => '%', :description => 'Percent Up'),
                           },
                           :thresholds => {
                               'LogstashProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
                           }
             }
          }       


resource "build",
  :cookbook => "oneops.1.build",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {
    "install_dir"   => '/usr/local/build',
    "repository"    => "",
    "remote"        => 'origin',
    "revision"      => 'HEAD',
    "depth"         => 1,
    "submodules"    => 'false',
    "environment"   => '{}',
    "persist"       => '[]',
    "migration_command" => '',
    "restart_command"   => ''
  }
  
resource "artifact",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {

  }
  
resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "9200 9400 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }
  
resource "hostname",
  :cookbook => "oneops.1.fqdn",
  :design => true,
  :requires => {
    :constraint => "0..1",
    :services => "dns",
    :help => "optional hostname dns entry"
  }  
  
resource "haproxy",
  :cookbook => "oneops.1.haproxy",
  :design => true,
  :requires => { "constraint" => "0..1" },
  :monitors => {
      'stats' => {:description => 'stats',
                     :chart => {'min' => 0, 'unit' => ''},
                     :cmd => 'check_haproxy',
                     :cmd_line => '/opt/nagios/libexec/check_haproxy.rb',
                     # see http://www.haproxy.org/download/1.5/doc/configuration.txt for more detail
                     :metrics => {
                         'requests' => metric(:unit => 'req/sec', :description => 'Requests /sec', :dstype => 'DERIVE'),
                         'current_sessions' => metric(:unit => 'count', :description => 'Current Sessions', :dstype => 'GAUGE'),
                         'errors_req' => metric(:unit => 'errors_req/sec', :description => 'Error Requests /sec', :dstype => 'DERIVE'),
                         'errors_conn' => metric(:unit => 'errors_conn/sec', :description => 'Error Connections /sec', :dstype => 'DERIVE'),
                         'errors_resp' => metric(:unit => 'errors_resp/sec', :description => 'Error Resp /sec', :dstype => 'DERIVE'),
                         'bytes_in' => metric(:unit => 'bytes/sec', :description => 'Bytes in /sec', :dstype => 'DERIVE'),
                         'bytes_out' => metric(:unit => 'bytes/sec', :description => 'Bytes out /sec', :dstype => 'DERIVE')
                     }
           }
  }  
  
  
# depends_on
[
 {:from => 'elasticsearch', :to => 'user-app'},
 {:from => 'elasticsearch', :to => 'os'},
 {:from => 'java',          :to => 'os'},
 {:from => 'user-app',      :to => 'os'},
 {:from => 'haproxy',       :to => 'os'},
 {:from => 'elasticsearch', :to => 'volume'},
 {:from => 'elasticsearch', :to => 'java'  },
 {:from => 'logstash',      :to => 'elasticsearch'},
 {:from => 'build',         :to => 'elasticsearch'},
 {:from => 'artifact',      :to => 'elasticsearch'},
 {:from => 'index',         :to => 'elasticsearch'},
 {:from => 'daemon',        :to => 'artifact'},
 {:from => 'daemon',        :to => 'build'}].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

# propagation rule for replace
[ 'hostname' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end


# managed_via
['user-app','elasticsearch','logstash','artifact','java','haproxy'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end
