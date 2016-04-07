name             "Rabbitmq"
description      "Installs/Configures ActiveMQ"
version          "0.1"
maintainer       "OneOps"
license          "Copyright OneOps, All rights reserved."

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'version',
  :description => "Version",
  :required => "required",
  :default => "3.4.2",
  :format => {
    :help => 'Version of RabbitMQ',
    :category => '1.Global',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['3.5.6','3.5.6'],['3.4.2','3.4.2'],['3.4.3','3.4.3'],['2.8.5','2.8.5']]}
  }
  
attribute 'src_url',
          :description => 'Source URL',
          :required => 'required',
          :default => 'https://www.rabbitmq.com/releases/rabbitmq-server/',
          :format => {
              :help => 'location of the Rabbitmq source distribution',
              :category => '1.Global',
              :order => 2
          }


attribute 'port',
  :description => "Port",
  :default => "5672",
  :format => {
    :help => 'Port RabbitMQ service listens on',
    :category => '1.Global',
    :order => 2,
    :pattern => "[0-9]+"
  }
  
attribute 'datapath',
  :description => "Data Directory",
  :default => "/data/rabbitmq/mnesia",
  :format => {
    :help => 'Directory path where RabbitMQ stores data',
    :category => '1.Global',
    :order => 2
  }
  
attribute 'erlangcookie',
  :description => "Erlang Cookie",
  :encrypted => true,
  :default => "DEFAULTCOOKIE",
  :format => {
    :help => 'Unique Erlang cookie used for inter-node communication',
    :category => '1.Global',
    :order => 2
  }
  
recipe "status", "Rabbitmq Status"
recipe "start", "Start Rabbitmq"
recipe "stop", "Stop Rabbitmq"
recipe "restart", "Restart Rabbitmq"
recipe "repair", "Repair Rabbitmq"
