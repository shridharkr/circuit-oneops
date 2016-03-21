name             "Queue"
description      "Queue"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'queuename',
          :description => 'Queue Name',
          :required => 'required',
          :format => {
              :help => 'Queue Name',
              :category => '2.Destination',
             :order => 1,
          }

attribute 'destinationtype',
          :description => 'Destination Type',
          :default => 'Q',
          :format => {
              :help => 'Destination type - Queue',
              :category => '1.Destination',
              :order => 2,
              :filter => {'all' => {'visible' => 'false'}},
              :editable => false
          }

attribute 'maxmemorysize',
          :description => 'Maximum Memory',
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


recipe 'purge',  'Purge ActiveMQ queue'
recipe 'repair', 'Repairs ActiveMQ resource'
