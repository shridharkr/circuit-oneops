include_pack  "genericlb"
name          "Tomcat-85"
description   "Tomcat 8_5 Version 7"
type          "Platform"
category      "Web Application"

environment "single", {}
environment "redundant", {}

resource "Tomcat-85",
         :cookbook => "1.Tomcat-85",
         :source => Chef::Config[:register],
         :design => true,
         :requires => {"constraint" => "1..1"},
         :attributes => {
             'install_dir' => '/app',
             'install_version' => '8.5.2',
             'server_user' => 'app',
             'server_group' => 'app',
             'java_jvm_args' => '-Xms64m -Xmx1024m',
             'java_system_properties' => '{
                    "com.walmart.platform.config.runOnEnv":"$OO_LOCAL{runOnEnv}",
                    "com.walmartlabs.pangaea.platform.config.runOnEnv":"$OO_LOCAL{runOnEnv}",
                    "com.walmart.platform.config.localConfigLocation":"/app/localConfig/$OO_LOCAL{artifactId}",
                    "com.walmart.platform.config.appName":"$OO_LOCAL{artifactId}",
                    "app.domain":"$OO_LOCAL{domain}",
                    "app.name":"$OO_LOCAL{name}"
                  }',
             'java_startup_params' => '[
                    "+UseCompressedOops",
                    "SurvivorRatio=10",
                    "SoftRefLRUPolicyMSPerMB=125"
                  ]',
             'access_log_dir' =>'/log/tomcat',
             'access_log_pattern'=>'%h %{NSC-Client-IP}i %l %u %t &quot;%r&quot; %s %b %D %F'
         },
         :monitors => {
             'JvmInfo' => {:description => 'JvmInfo',
                           :source => '',
                           :chart => {'min' => 0, 'unit' => ''},
                           :cmd => 'check_tomcat_jvm',
                           :cmd_line => '/opt/nagios/libexec/check_tomcat.rb JvmInfo',
                           :metrics => {
                               'max' => metric(:unit => 'B', :description => 'Max Allowed', :dstype => 'GAUGE'),
                               'free' => metric(:unit => 'B', :description => 'Free', :dstype => 'GAUGE'),
                               'total' => metric(:unit => 'B', :description => 'Allocated', :dstype => 'GAUGE'),
                               'percentUsed' => metric(:unit => 'Percent', :description => 'Percent Memory Used', :dstype => 'GAUGE'),
                           },
                           :thresholds => {
                              'HighMemUse' => threshold('1m','avg', 'percentUsed',trigger('>=',90,5,1),reset('<',85,5,1)),
                           }
             },
             'ThreadInfo' => {:description => 'ThreadInfo',
                              :source => '',
                              :chart => {'min' => 0, 'unit' => ''},
                              :cmd => 'check_tomcat_thread',
                              :cmd_line => '/opt/nagios/libexec/check_tomcat.rb ThreadInfo',
                              :metrics => {
                                  'currentThreadsBusy' => metric(:unit => '', :description => 'Busy Threads', :dstype => 'GAUGE'),
                                  'maxThreads' => metric(:unit => '', :description => 'Maximum Threads', :dstype => 'GAUGE'),
                                  'currentThreadCount' => metric(:unit => '', :description => 'Ready Threads', :dstype => 'GAUGE'),
                                  'percentBusy' => metric(:unit => 'Percent', :description => 'Percent Busy Threads', :dstype => 'GAUGE'),
                              },
                              :thresholds => {
                                 'HighThreadUse' => threshold('5m','avg','percentBusy',trigger('>=',90,5,1),reset('<',85,5,1)),
                              }
             },
             'RequestInfo' => {:description => 'RequestInfo',
                               :source => '',
                               :chart => {'min' => 0, 'unit' => ''},
                               :cmd => 'check_tomcat_request',
                               :cmd_line => '/opt/nagios/libexec/check_tomcat.rb RequestInfo',
                               :metrics => {
                                   'bytesSent' => metric(:unit => 'B/sec', :description => 'Traffic Out /sec', :dstype => 'DERIVE'),
                                   'bytesReceived' => metric(:unit => 'B/sec', :description => 'Traffic In /sec', :dstype => 'DERIVE'),
                                   'requestCount' => metric(:unit => 'reqs /sec', :description => 'Requests /sec', :dstype => 'DERIVE'),
                                   'errorCount' => metric(:unit => 'errors /sec', :description => 'Errors /sec', :dstype => 'DERIVE'),
                                   'maxTime' => metric(:unit => 'ms', :description => 'Max Time', :dstype => 'GAUGE'),
                                   'processingTime' => metric(:unit => 'ms', :description => 'Processing Time /sec', :dstype => 'DERIVE')
                               },
                               :thresholds => {
                               }
             },
             'Log' => {:description => 'Log',
                       :source => '',
                       :chart => {'min' => 0, 'unit' => ''},
                       :cmd => 'check_logfiles!logtomcat!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                       :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                       :cmd_options => {
                           'logfile' => '/log/tomcat/catalina.out',
                           'warningpattern' => 'WARNING',
                           'criticalpattern' => 'CRITICAL'
                       },
                       :metrics => {
                           'logtomcat_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                           'logtomcat_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                           'logtomcat_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                           'logtomcat_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                       },
                       :thresholds => {
                         'CriticalLogException' => threshold('15m', 'avg', 'logtomcat_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1)),
                       }
             },
            'ResponseCodeInfo' => {:description => 'ResponseCodeInfo',
                              :source => '',
                              :chart => {'min' => 0, 'unit' => ''},
                              :cmd => 'check_es_response',
                              :cmd_line => '/opt/nagios/libexec/check_es_response.rb /log/tomcat/response_log.txt',
                              :metrics => {
                                  'rc200' => metric(:unit => 'min', :description => 'Response code 200', :dstype => 'GAUGE'),
                                  'rc304' => metric(:unit => 'min', :description => 'Response code 304', :dstype => 'GAUGE'),
                                  'rc404' => metric(:unit => 'min', :description => 'Response code 404', :dstype => 'GAUGE'),
                                  'rc500' => metric(:unit => 'min', :description => 'Response code 500', :dstype => 'GAUGE'),
                                  'rc2xx' => metric(:unit => 'min', :description => 'Response code family 2xx', :dstype => 'GAUGE'),
                                  'rc3xx' => metric(:unit => 'min', :description => 'Response code family 3xx', :dstype => 'GAUGE'),
                                  'rc4xx' => metric(:unit => 'min', :description => 'Response code family 4xx', :dstype => 'GAUGE'),
                                  'rc5xx' => metric(:unit => 'min', :description => 'Response code family 5xx', :dstype => 'GAUGE')
                              },
                              :thresholds => {
                              }
            }
         }

resource "Tomcat-85-daemon",
         :cookbook => "oneops.1.daemon",
         :design => true,
         :requires => {
             :constraint => "0..1",
             :help => "Restarts Tomcat"
         },
         :attributes => {
             :service_name => 'Tomcat-85',
             :use_script_status => 'true',
             :pattern => ''
         },
         :monitors => {
             'tomcatprocess' => {:description => 'TomcatProcess',
                           :source => '',
                           :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                           :cmd => 'check_process!:::node.workorder.rfcCi.ciAttributes.service_name:::!:::node.workorder.rfcCi.ciAttributes.use_script_status:::!:::node.workorder.rfcCi.ciAttributes.pattern:::!:::node.workorder.rfcCi.ciAttributes.secondary_down:::',
                           :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$" "$ARG4$"',
                           :metrics => {
                               'up' => metric(:unit => '%', :description => 'Percent Up'),
                           },
                           :thresholds => {
                               'TomcatDaemonProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
                           }
             }
          }
resource "keystore",
         :cookbook => "oneops.1.keystore",
         :design => true,
         :requires => {"constraint" => "0..1"},
         :attributes => {
             "keystore_filename" => "/var/lib/certs/keystore.jks"
         }

resource "artifact",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {

  },
  :monitors => {
         'URL' => {:description => 'URL',
                   :source => '',
                   :chart => {'min' => 0, 'unit' => ''},
                   :cmd => 'check_http_status!#{cmd_options[:host]}!#{cmd_options[:port]}!#{cmd_options[:url]}!#{cmd_options[:wait]}!#{cmd_options[:expect]}!#{cmd_options[:regex]}',
                   :cmd_line => '/opt/nagios/libexec/check_http_status.sh $ARG1$ $ARG2$ "$ARG3$" $ARG4$ "$ARG5$" "$ARG6$"',
                   :cmd_options => {
                       'host' => 'localhost',
                       'port' => '8080',
                       'url' => '/',
                       'wait' => '15',
                       'expect' => '200 OK',
                       'regex' => ''
                   },
                   :metrics => {
                       'time' => metric(:unit => 's', :description => 'Response Time', :dstype => 'GAUGE'),
                       'up' => metric(:unit => '', :description => 'Status', :dstype => 'GAUGE'),
                       'size' => metric(:unit => 'B', :description => 'Content Size', :dstype => 'GAUGE', :display => false)
                   },
                   :thresholds => {

                   }
         },
          'exceptions' => {:description => 'Exceptions',
                     :source => '',
                     :chart => {'min' => 0, 'unit' => ''},
                     :cmd => 'check_logfiles!logexc!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                     :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol  --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                     :cmd_options => {
                         'logfile' => '/log/logmon/logmon.log',
                         'warningpattern' => 'Exception',
                         'criticalpattern' => 'Exception'
                     },
                     :metrics => {
                         'logexc_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                         'logexc_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                         'logexc_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                         'logexc_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                     },
                     :thresholds => {
                       'CriticalExceptions' => threshold('15m', 'avg', 'logexc_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1))
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

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "8080 8080 tcp 0.0.0.0/0", "8009 8009 tcp 0.0.0.0/0", "8443 8443 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource 'java',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => '*mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {}


# depends_on
[ { :from => 'Tomcat-85',     :to => 'os' },
  { :from => 'Tomcat-85',     :to => 'user'  },
  { :from => 'Tomcat-85-daemon',     :to => 'compute' },
  { :from => 'Tomcat-85',     :to => 'java'  },
  { :from => 'Tomcat-85',     :to => 'volume'},
  { :from => 'Tomcat-85',     :to => 'keystore'},
  { :from => 'artifact',   :to => 'library' },
  { :from => 'artifact',   :to => 'Tomcat-85'  },
  { :from => 'artifact',   :to => 'download'},
  { :from => 'artifact',   :to => 'build'},
  { :from => 'artifact',   :to => 'volume'},
  { :from => 'build',      :to => 'library' },
  { :from => 'build',      :to => 'Tomcat-85'  },
  { :from => 'build',      :to => 'download'},
  { :from => 'daemon',     :to => 'artifact' },
  { :from => 'daemon',     :to => 'build' },
  { :from => 'java',       :to => 'compute' },
  { :from => 'java',       :to => 'os' },
  { :from => 'keystore',    :to => 'java'},
  { :from => 'java',       :to => 'download'} ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

relation "Tomcat-85-daemon::depends_on::artifact",
  :relation_name => 'DependsOn',
  :from_resource => 'Tomcat-85-daemon',
  :to_resource => 'artifact',
  :attributes => {"propagate_to" => "from", "flex" => false, "min" => 1, "max" => 1}

relation "Tomcat-85-daemon::depends_on::keystore",
  :relation_name => 'DependsOn',
  :from_resource => 'Tomcat-85-daemon',
  :to_resource => 'keystore',
  :attributes => {"propagate_to" => "from", "flex" => false, "min" => 1, "max" => 1}

relation "keystore::depends_on::certificate",
  :relation_name => 'DependsOn',
  :from_resource => 'keystore',
  :to_resource => 'certificate',
  :attributes => {"propagate_to" => "from", "flex" => false, "min" => 1, "max" => 1}


# managed_via
[ 'Tomcat-85', 'artifact', 'build', 'java','keystore', 'Tomcat-85-daemon'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
