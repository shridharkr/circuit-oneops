name             'Node_module'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          "Apache License, Version 2.0"
description      'Installs/Configures node_module'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1'

recipe "status", "Node Status"
recipe "start", "Start Node application"
recipe "stop", "Stop Node application"
recipe "restart", "Restart Node application"
recipe "repair", "Repair Nodejs"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom' ]


attribute 'name',
  :description => "Name of application",
  :format => {
    :category => '1.Global',
    :order => 1,
    :help => 'Name of your application node module without the @walmart'
  }

attribute 'module_name',
  :description => "NPM node module name",
  :format => {
    :category => '1.Global',
    :order => 1,
    :help => 'NPM node module name'
  }

attribute 'module_version',
  :description => "NPM node module version",
  :format => {
    :category => '1.Global',
    :order => 2,
    :help => 'NPM node module version'
  }

attribute 'server_root',
  :description => "Location of the server",
  :default => '/app',
  :format => {
    :category => '1.Global',
    :order => 3,
    :help => 'Location of the server'
  }

attribute 'options',
  :description => 'Options for node',
  :default => '-p 8080 -e DEV',
  :format => {
    :category => '1.Global',
    :order => 4,
    :help => 'Options for node'
  }

attribute 'script_location',
  :description => "Server start up script",
  :format => {
    :category => '1.Global',
    :order => 5,
    :help => 'Start node options'
  }

attribute 'log_file',
  :description => "Log file location",
  :default => "/log/nodejs/app.js.log",
  :format => {
    :category => '1.Global',
    :order => 6,
    :help => 'location of log file'
  }

attribute 'as_user',
  :description => 'app user',
  :default => 'app',
  :format => {
    :category => '1.Global',
    :order => 7,
    :help => 'The user which the app will be run as'
  }
