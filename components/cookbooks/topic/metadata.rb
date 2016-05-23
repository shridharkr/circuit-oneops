name             "Topic"
description      "Topic"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'topicname',
          :description => 'Topic Name',
          :required => 'required',
          :format => {
              :help => 'Topic Name',
              :category => '1.Destination',
              :editable => false,
             :order => 1,
          }

attribute 'destinationtype',
          :description => 'Destination Type',
          :default => 'T',
          :format => {
              :help => 'Destination type - Topic',
              :category => '1.Destination',
              :order => 2,
              :form => {'field' => 'select', 'options_for_select' => [['Topic', 'T'], ['Composite Topic', 'compositeTopic'], ['Virtual Topic', 'virtualTopic']]}
          }

attribute 'maxmemorysize',
          :description => 'Max Memory',
          :default => '0',
          :format => {
              :help => 'Max message memory for Topic. 0 means no limit.',
              :category => '1.Destination',
              :filter => {'all' => {'visible' => 'false'}},
              :order => 3
          }

attribute 'permission',
          :description => "User Permission",
          :data_type => "hash",
          :default => '{"readonly":"R"}',
          :format => {
            :help => 'User permissions. eg (username:permission). Valid values for permissions are R for READ, W for WRITE and RW ReadWrite',
            :category => '2.Permissions',
            :pattern  => [["Readonly", "R"], ["Write", "W"], ["Read and Write", "RW"]] ,
            :order => 1
          }

attribute 'destinationpolicy',
          :description => "Destination Policy",
          :data_type => "text",
          :default => "",
          :format => {
            :help => 'Define destination policy specifically for this topic',
            :category => '3.DestinationPolicy',
            :order => 1
          }

attribute 'virtualdestination',
          :description => "Composite/Virtual Topic Definition",
          :data_type => "text",
          :default => "",
          :format => {
            :help => 'Composite/Virtual Topic Definition',
            :category => '4.CompositeTopic',
            :filter => {'all' => {'visible' => 'destinationtype:neq:T'}},
            :order => 1
          }

recipe 'repair', 'Repairs ActiveMQ resource'
