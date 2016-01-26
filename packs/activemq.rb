include_pack "genericmq"

name "activemq"
description "ActiveMQ"
type "Platform"
category "Messaging"

resource "activemq",
  :cookbook => "oneops.1.activemq",
  :design => true,
  :requires => { 
      :constraint => "1..1",
      :services => "mirror",
      :help => 'ActiveMQ Server'
    },
  :attributes => { "version"       => "5.11.3",
                   "memory"        => 512 
                  },
  :monitors => {
      'Log' => {:description => 'Log',
                     :source => '',
                     :chart => {'min' => 0, 'unit' => ''},
                     :cmd => 'check_logfiles!logmqexc!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                     :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol  --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                     :cmd_options => {
                         'logfile' => '/opt/activemq/data/wrapper.log',
                         'warningpattern' => 'OutOfMemory',
                         'criticalpattern' => 'OutOfMemory'
                     },
                     :metrics => {
                         'logmqexc_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                         'logmqexc_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                         'logmqexc_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                         'logmqexc_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                     },
                     :thresholds => {
                       'CriticalExceptions' => threshold('15m', 'avg', 'logmqexc_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1))
                    }
           },
           'Memory' => {:description => 'Memory Status',
                   :source => '',
                   :chart => {'min' => 0, 'unit' => ''},
                   :cmd => 'check_activemq_mem!#{cmd_options[:protocol]}!#{cmd_options[:port]}!#{cmd_options[:path]}!:::node.workorder.rfcCi.ciAttributes.authenabled:::!:::node.workorder.rfcCi.ciAttributes.adminusername:::!:::node.workorder.rfcCi.ciAttributes.adminpassword:::',
                   :cmd_line => '/opt/nagios/libexec/check_activemq_mem.rb $ARG1$ $ARG2$ $ARG3$ $ARG4$ $ARG5$ $ARG6$',
                   :cmd_options => {
                        'protocol' => 'http',
                         'port' => '8161',
                         'path' => '/admin/index.jsp?printable=true'
                      },
                   :metrics => {
                       'Temp_percent_used' => metric(:unit => '', :description => 'Temp percent used', :dstype => 'GAUGE'),
                       'Memory_percent_used' => metric(:unit => '', :description => 'Memory percent used', :dstype => 'GAUGE'),
                       'Store_percent_used' => metric(:unit => '', :description => 'Store percent used', :dstype => 'GAUGE')
                   },
                   :thresholds => {
                     
                   }
         },
     'BrokerStatus' =>  { :description => 'BrokerStatus',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>''},
                  :cmd => 'check_activemq!#{cmd_options[:protocol]}!#{cmd_options[:port]}!:::node.workorder.rfcCi.ciAttributes.authenabled:::!:::node.workorder.rfcCi.ciAttributes.adminusername:::!:::node.workorder.rfcCi.ciAttributes.adminpassword:::',
                  :cmd_line => '/opt/nagios/libexec/check_activemq.rb $ARG1$ $ARG2$ $ARG3$ $ARG4$ $ARG5$',
                   :cmd_options => {
                        'protocol' => 'http',
                         'port' => '8161'
                      },
                   :metrics =>  {
                    'queue_count'   => metric( 
                        :unit => '', 
                        :description => 'Queue Count', 
                        :dstype => 'GAUGE', 
                        :display_group => "Queues"),
                    'queue_backlog'   => metric( 
                        :unit => '', 
                        :description => 'Queue Backlog', 
                        :dstype => 'GAUGE', 
                        :display_group => "Queues"),
                    'queue_consumer_count'   => metric( 
                        :unit => '', 
                        :description => 'Queue Consumer Count', 
                        :dstype => 'GAUGE', 
                        :display_group => "Queues"),
                    'queue_enqueues'   => metric( 
                        :unit => 'PerSecond', 
                        :description => 'Queue in messages /sec', 
                        :dstype => 'DERIVE', 
                        :display_group => "Queue Rates" ),
                    'queue_dequeues'   => metric( 
                        :unit => 'PerSecond', 
                        :description => 'Queue out messages /sec', 
                        :dstype => 'DERIVE', 
                        :display_group => "Rates"),
                    'topic_count'   => metric( 
                        :unit => '', 
                        :description => 'Topic Count', 
                        :dstype => 'GAUGE', 
                        :display_group => "Topics"),
                    'topic_backlog'   => metric( 
                        :unit => '', 
                        :description => 'Topic Backlog', 
                        :dstype => 'GAUGE', 
                        :display_group => "Topics"),
                    'topic_consumer_count'   => metric( 
                        :unit => '', 
                        :description => 'Topic Consumer Count', 
                        :dstype => 'GAUGE', 
                        :display_group => "Topics"),
                    'topic_enqueues'   => metric( 
                        :unit => 'PerSecond', 
                        :description => 'Topic in messages /sec', 
                        :dstype => 'DERIVE', 
                        :display_group => "Topic Rates"),
                    'topic_dequeues'   => metric( 
                        :unit => 'PerSecond', 
                        :description => 'Topic out messages /sec', 
                        :dstype => 'DERIVE', 
                        :display_group => "Topic Rates"),
                  },
                  # TODO: update with dynamic threshold - Seasonality/previous cycles avg as threshold
                  :thresholds => {
                     'HighBacklog' => threshold(
                          '5m','avg','queue_backlog',
                              trigger('>',100,5,1),
                              reset('<',100,5,1)),
                  }
                } 
  }  

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "61616 61617 tcp 0.0.0.0/0","8161 8162 tcp 0.0.0.0/0"]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource "activemq-daemon",
         :cookbook => "oneops.1.daemon",
         :design => true,
         :requires => {
             :constraint => "1..1",
             :help => "Restarts ActiveMQ"
         },
         :attributes => {
             :service_name => 'activemq',
             :use_script_status => 'true',
             :pattern => ''
         },
         :monitors => {
             'activemqprocess' => {:description => 'ActiveMQProcess',
                           :source => '',
                           :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                           :cmd => 'check_process!:::node.workorder.rfcCi.ciAttributes.service_name:::!:::node.workorder.rfcCi.ciAttributes.use_script_status:::!:::node.workorder.rfcCi.ciAttributes.pattern:::',
                           :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                           :metrics => {
                               'up' => metric(:unit => '%', :description => 'Percent Up'),
                           },
                           :thresholds => {
                               'ActiveMQDaemonProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
                           }
             }
          }

  
resource "configfile",
  :cookbook => "oneops.1.file",
  :design => true,
  :requires => {
    :constraint => "0..*",
    :help => "This is used to create the config files. Copy the content in the content field and provide the complete path including the name in the path."
  }
  
resource "build",
  :cookbook => "oneops.1.build",
  :design => true,
  :requires => { "constraint" => "0..*" }


resource "artifact",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {

  }

resource "java",
         :cookbook => "oneops.1.java",
         :design => true,
         :requires => { "constraint" => "0..1"},
         :attributes => {
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
['activemq','java','haproxy'].each do |from|
  
  relation "#{from}::depends_on::os",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'os',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end


[ 'activemq' ].each do |from|
  relation "#{from}::depends_on::java",
           :relation_name => 'DependsOn',
           :from_resource => from,
           :to_resource   => 'java',
           :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

[ 'activemq' ].each do |from|
  relation "#{from}::depends_on::volume",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'volume',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'build', 'artifact', 'configfile', 'activemq-daemon' ].each do |from|
  relation "#{from}::depends_on::activemq",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'activemq',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'activemq-daemon' ].each do |from|
  relation "#{from}::depends_on::artifact",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'artifact',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'queue', 'topic' ].each do |from|
  relation "#{from}::depends_on::activemq",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'activemq',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

# managed_via
[ 'activemq', 'build','artifact','configfile', 'activemq-daemon','java','haproxy' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default'],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end

