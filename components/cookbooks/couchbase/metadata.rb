name              "Couchbase"
description       "Installs/Configures couchbase"
version           "0.1"
maintainer        "OneOps"
maintainer_email  "support@oneops.com"
license           "Apache License, Version 2.0"


grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


# Couchbase mirror
attribute 'mirrors',
          :description => 'Mirrors',
          :data_type => 'array',
          :default => '[]',
          :format => {
              :category => '1.Global',
              :help => "Couchbase binary distribution mirrors - uri without /version/artifact.rpm path. Uses official or cloud mirror if it's empty.",
              :order => 1,
              :editable => false
          }

attribute 'distributionurl',
          :description => 'Binary Distribution',
          :default => 'http://gec-maven-nexus.walmart.com/nexus/content/repositories/thirdparty/com/couchbase/server/couchbase-server-enterprise/',
          :format => {
            :category => '1.Global',
            :help => "Couchbase binary distribution mirrors. Select official or cloud mirror.",
            :order => 1,
            :form => {'field' => 'select', 'options_for_select' => [['Nexus', 'http://gec-maven-nexus.walmart.com/nexus/content/repositories/thirdparty/com/couchbase/server/couchbase-server-enterprise/'], ['Couchbase', 'http://packages.couchbase.com/releases/']]
            }
          }


attribute 'version',
          :description => 'Version',
          :required => 'required',
          :default => '2.5.2',
          :format => {
              :help => 'Version of Couchbase',
              :category => '1.Global',
              :order => 2,
              :form => {'field' => 'select', 'options_for_select' => [['3.0.3', '3.0.3'], ['2.5.2', '2.5.2'], ['2.2.0', '2.2.0']]}
          }

attribute 'upgradecouchbase',
          :description => "Upgrade CouchBase",
          :default => 'false',
          :format => {
              :help => 'If selected, CouchBase Server will be upgraded to selected version',
              :category => '1.Global',
              :order => 3,
              :form => { 'field' => 'checkbox' }
          }


attribute 'arch',
          :description => 'Arch',
          :required => 'required',
          :default => 'x86_64',
          :format => {
              :help => 'Processor architecture. x86_64 (64 bit) or x86 (32 bit).',
              :category => '1.Global',
              :order => 4,
	            :editable => false
          }
        #      :form => {'field' => 'select', 'options_for_select' => [['x86_64', 'x86_64'], ['x86', 'x86']]}
        #  }


attribute 'edition',
          :description => "Edition",
          :required => "required",
          :default => 'enterprise',
          :format => {
              :help => 'Edition. By default it uses Enterprise edition.',
              :category => '1.Global',
              :order => 5,
	            :editable => false
          }
        #      :form => {'field' => 'select', 'options_for_select' => [['Enterprise', 'enterprise'], ['Community'], ['community']]}
        #  }


attribute 'checksum',
          :description => "Checksum",
          :format => {
              :category => '1.Global',
              :help => 'SHA-256 checksum of the file',
	            :editable => false,
              :order => 6
          }

# cluster
attribute 'port',
          :description => "Cluster Management Port",
          :default => "8091",
          :format => {
              :help => 'Couchbase web console and cluster management port',
              :category => '2.Cluster',
              :order => 1,
              :editable => false,
          }

attribute 'adminuser',
          :description => "Admin User",
          :required => "required",
          :default => "Administrator",
          :format => {
              :help => 'Cluster administration username',
              :category => '2.Cluster',
              :order => 2
          }

attribute 'adminpassword',
          :description => "Admin Password",
          :encrypted => true,
          :required => "required",
          :default => "password",
          :format => {
              :help => 'Cluster administration password',
              :category => '2.Cluster',
              :order => 3
          }


attribute 'pernoderamquotamb',
          :description => "RAM quota percentage per node",
          :default => "80%",
          :format => {
              :help => 'Per node RAM quota percentage',
              :category => '2.Cluster',
              :order => 4,
              :editable => true,
              :form => {'field' => 'select', 'options_for_select' => [['80%', '80%'], ['60%', '60%']]}
          }

# Buckets
attribute 'datapath',
          :description => "Buckets Data Path",
          :default => "/opt/couchbase/data",
          :format => {
              :help => 'Directory path where bucket data files will be stored',
              :category => '3.Buckets',
              :order => 4,
              :editable => true
          }

# Settings
attribute 'updatenotification',
          :description => "CouchBase update notification.",
          :default => 'false',
          :format => {
              :help => 'Directory path where bucket data files will be stored',
              :category => '4.Settings',
              :order => 1,
              :form => { 'field' => 'checkbox' }
          }


attribute 'autofailovertime',
          :description => "Auto Fail Over in seconds",
          :default => '120',
          :format => {
              :help => 'The timeout before the auto-failover process is started when a cluster node failure is detected',
              :category => '4.Settings',
              :order => 2

          }

attribute 'autocompaction',
          :description => "Auto Compaction % Level",
          :default => '75',
          :format => {
              :help => 'Database Fragmentation at which point compaction is triggered. Range 20% to 80%',
              :category => '4.Settings',
              :order => 3

          }

attribute 'host',
          :description => "Email Server Host",
          :default => 'smtp',
          :format => {
              :help => 'SMTP Host',
              :category => '4.Settings',
              :order => 4

          }

attribute 'emailport',
          :description => "Email Server Port",
          :default => '25',
          :format => {
              :help => 'SMTP Port',
              :category => '4.Settings',
              :order => 5

          }


attribute 'sender',
          :description => "Sender email",
          :default => 'couchbase@example.com',
          :format => {
              :help => 'Sender Email eg: couchbase@example.com',
              :category => '4.Settings',
              :order => 6

          }

attribute 'recipents',
          :description => "Email Recipents",
          :default => 'admin@example.com',
          :format => {
              :help => 'Recipents addresses with comma separated',
              :category => '4.Settings',
              :order => 7

          }



recipe "status", "Couchbase Status"
recipe "start", "Start Couchbase"
recipe "stop", "Stop Couchbase"
recipe "restart", "Restart Couchbase"
recipe "repair", "Repair Couchbase"
recipe "remove-from-cluster", "Remove Couchbase server from cluster"
recipe "add-to-cluster", "Add Couchbase server to cluster"

