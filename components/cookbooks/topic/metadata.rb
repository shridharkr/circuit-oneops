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
              :category => '2.Destination',
             :order => 1,
          }

attribute 'destinationtype',
          :description => 'Destination Type',
          :default => 'T',
          :format => {
              :help => 'Destination type - Topic',
              :category => '1.Destination',
              :order => 2,
              :filter => {'all' => {'visible' => 'false'}},
              :editable => false
          }

attribute 'maxmemorysize',
          :description => 'Max Memory',
          :default => '0',
          :format => {
              :help => 'Max message memory for Queue.0 mean no limit.',
              :category => '2.Destination',
              :order => 3
          }

attribute 'permission',
          :description => "User Permission",
          :data_type => "hash",
          :default => '{"readonly":"R"}',
          :format => {
            :help => 'User permissions. eg (username:permission). Valid values for permissions are R for READ, W for WRITE and RW ReadWrite',
            :category => '3.Permissions',
            :order => 1
          }


recipe 'repair', 'Repairs ActiveMQ resource'