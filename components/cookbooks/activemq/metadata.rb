name              'Activemq'
description       'Installs/Configures ActiveMQ'
version           '0.1'
maintainer        'OneOps'
maintainer_email  'support@oneops.com'
license           'Copyright OneOps, All rights reserved.'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


attribute 'version',
          :description => 'Version',
          :required => 'required',
          :default => '5.11.3',
          :format => {
              :help => 'Version of ActiveMQ',
              :category => '1.Global',
              :order => 1,
              :form => {'field' => 'select', 'options_for_select' => [['5.5.1', '5.5.1'], ['5.9.1', '5.9.1'], ['5.10.0', '5.10.0'], ['5.11.3', '5.11.3']]}
          }

attribute 'initmemory',
          :description => 'Init Memory',
          :required => 'optional',
          :default => '256',
          :format => {
              :help => 'Init amount of memory to be used',
              :category => '1.Global',
              :order => 2
          }

attribute 'maxmemory',
          :description => 'Max Memory',
          :required => 'optional',
          :default => '512',
          :format => {
              :help => 'Maximimum amount of memory to be used',
              :category => '1.Global',
              :order => 3
          }

attribute 'transportconnector',
          :description => 'Transport Connectors',
          :required => 'required',
          :data_type => 'hash',
          :default => '{
             "openwire":"tcp://0.0.0.0:61616",
             "openwire-ssl":"ssl://0.0.0.0:61617"
          }',
          :format => {
              :help => 'Transport Connectors',
              :category => '1.Global',
              :order => 4
          }


attribute 'environment',
          :description => 'Environment Variables',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :help => 'Environment variables to be set for this ActiveMQ instance',
              :category => '2.Server',
              :order => 1
          }

attribute 'authenabled',
          :description => 'Enabled Authentication ',
          :default => 'false',
          :format => {
              :category => '2.Server',
              :help => 'Enable Authentication',
              :form => {'field' => 'checkbox'},
              :order => 2
          }

attribute 'adminusername',
          :description => 'Auth Username',
          :format => {
              :category => '2.Server',
              :help => 'Username for the Authentication',
              :filter => {'all' => {'visible' => 'authenabled:eq:true'}},
              :order => 3
          }

attribute 'adminpassword',
          :description => 'Auth Password',
          :encrypted => true,
          :format => {
              :category => '2.Server',
              :help => 'Password for the Authentication',
              :filter => {'all' => {'visible' => 'authenabled:eq:true'}},
              :order => 4
          }
attribute 'adminconsoleport',
          :description => 'Connector Port',
          :required => 'required',
          :default => '8161',
          :format => {
              :help => 'Connector port for the Web console',
              :category => '2.Server',
              :order => 5
          }

attribute 'adminconsolesecure',
          :description => 'Admin console Secure',
          :default => 'false',
          :format => {
              :category => '2.Server',
              :help => 'Admin Console is Secure',
              :form => {'field' => 'checkbox'},
              :order => 6
          }

attribute 'adminconsolekeystore',
          :description => 'Admin console ',
          :default => '',
          :format => {
              :category => '2.Server',
              :help => 'Admin Console Keystore eg: file:<filelocation> ',
              :filter => {'all' => {'visible' => 'adminconsolesecure:eq:true'}},
              :order => 7
          }

attribute 'adminconsolekeystorepassword',
          :description => 'Admin Console Secure Password',
          :encrypted => true,
          :format => {
              :category => '2.Server',
              :help => 'Password for the Admin Console Keystore',
              :filter => {'all' => {'visible' => 'adminconsolesecure:eq:true'}},
              :order => 8
          }

attribute 'brokerauthenabled',
          :description => 'Broker Secure',
          :default => 'false',
          :format => {
              :category => '2.Server',
              :help => 'Broker is Secure',
              :form => {'field' => 'checkbox'},
              :order => 9
          }

attribute 'brokerusername',
          :description => 'Broker Username',
          :format => {
              :category => '2.Server',
              :help => 'Username for the Broker Authentication',
              :filter => {'all' => {'visible' => 'brokerauthenabled:eq:true'}},
              :order => 10
          }

attribute 'brokerpassword',
          :description => 'Broker Password',
          :encrypted => true,
          :format => {
              :category => '2.Server',
              :help => 'Password for the Broker Authentication',
              :filter => {'all' => {'visible' => 'brokerauthenabled:eq:true'}},
              :order => 11
          }

attribute 'mirrors',
          :description => 'Binary distribution mirrors',
          :required => 'required',
          :data_type => 'array',
          :default => '[]',
          :format => {
              :category => '1.Mirror',
              :help => 'Apache distribution compliant mirrors - uri without /tomcat/tomcat-x/... path',
              :order => 1
          }

attribute 'checksum',
          :description => 'Binary distribution checksum',
          :format => {
              :category => '1.Mirror',
              :help => 'md5 checksum of the file',
              :order => 2
          }


recipe 'status', 'ActiveMQ Status'
recipe 'start', 'Start ActiveMQ'
recipe 'stop', 'Stop ActiveMQ'
recipe 'restart', 'Restart ActiveMQ'
recipe 'repair', 'Repair ActiveMQ'
