name             'Graphite'
maintainer       'OneOps'
maintainer_email  'support@oneops.com'
license           'Apache License, Version 2.0'
version          '1.0.0'
description      'Graphite is a scalable realtime open source tool for monitoring and graphing the performance of computer systems'

grouping 'default',
:access => 'global',
:packages => %w(base mgmt.catalog mgmt.manifest catalog manifest bom)

attribute 'version',
:description          => 'Graphtie version',
:required => "required",
:default               => '0.9.15',
:format => {
    :category => '1.Global',
    :help => 'Graphtie version',
    :order => 1,
    :form => {'field' => 'select', 'options_for_select' => [['0.9.15', '0.9.15']]}
}

attribute 'replication_factor',
    :description          => 'Replication factor of Graphite metric data',
    :required => "required",
    :default               => '1',
    :format => {
        :category => '1.Global',
        :help => 'Replication factor defined in carbon.conf. If you want to add redundancy to your data by replicating every datapoint to more than one machine, increase this',
        :order => 2
}

attribute 'override_storage-schemas',
    :description => 'Override storage-schemas.conf Content',
    :data_type => "text",
    :format => {
       :category => '1.Global',
       :help => 'Will use this storage-schemas.conf file',
       :order => 3
   }

attribute 'override_storage-aggregation',
   :description => 'Override storage-aggregation.conf Content',
   :data_type => "text",
   :format => {
      :category => '1.Global',
      :help => 'Will use this storage-aggregation.conf file',
      :order => 4
}

recipe "status", "Graphite Status"
recipe "start", "Start Graphite"
recipe "restart", "Resgitart Graphite"
recipe "stop", "Stop Graphite"
recipe "repair", "Repair Graphitee"
recipe "clean", "Cleanup Graphite"
