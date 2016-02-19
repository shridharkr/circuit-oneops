name             "Node"
description      "Installs/Configures Node.js"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Copyright OneOps, All rights reserved."


recipe "status", "Node Status"
recipe "start", "Start Node application"
recipe "stop", "Stop Node application"
recipe "restart", "Restart Node application"


grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom' ]

attribute 'install_method',
  :description => "Install via (package or binary)",
  :default => "binary",
  :format => {
    :category => '1.Global',
    :order => 1,
    :help => 'Installation method',
    :form => {'field' => 'select', 'options_for_select' => [['binary', 'binary'], ['package', 'package']]}
  }

attribute 'version',
  :description => "Version",
  :default => "0.10.33",
  :format => {
    :category => '1.Global',
    :order => 2,
    :help => 'Version of Node.js' ,
    :form => {'field' => 'select', 'options_for_select' => [['0.10.33','0.10.33'],['0.10.41','0.10.41'],['0.12.4','0.12.4'],['4.2.4','4.2.4']]}
  }

attribute 'src_url',
  :description => "Location of nodejs binary",
  :format => {
    :category => '1.Global',
    :order => 3,
    :help => 'Specify a list of node source ',
    :filter => {'all' => {'visible' => 'install_method:eq:binary'}}
  }

attribute 'dir',
  :description => "Install location",
  :format => {
    :category => '1.Global',
    :order => 4,
    :help => 'Node install location'
  }

attribute 'checksum_linux_x64',
  :description => "Checksum",
  :format => {
    :category => '1.Global',
    :order => 5,
    :help => 'Check Sum of the binary',
    :filter => {'all' => {'visible' => 'install_method:eq:binary'}}
  }

attribute 'npm_src_url',
  :description => "NPM source URL",
  :format => {
    :category => '1.Global',
    :order => 6,
    :help => 'NPM resgistry URL',
    :filter => {'all' => {'visible' => 'install_method:eq:binary'}}
  }

attribute 'npm',
  :description => "NPM version",
  :format => {
    :category => '1.Global',
    :order => 7,
    :help => 'NPM version'
  }

recipe "repair", "Repair Nodejs"
