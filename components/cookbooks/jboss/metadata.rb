name             "Jboss"
description      "Installs/Configures JBoss"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

# default grouping for standard component 
grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'version',
  :description => "Version",
  :required => "required",
  :default => "7.1.1",
  :format => {
    :help => 'Version of JBoss',
    :category => '1.Global',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['7.1.1','7.1.1'],['7.0.2','7.0.2']] }
  }  

attribute 'jboss_home',
  :description => "JBoss Home",
  :required => "required",
  :default => "/opt/jboss",
  :format => {
    :help => 'JBoss Home Directory',
    :category => '1.Global',
    :order => 2
  } 

attribute 'jboss_user',
  :description => "JBoss User",
  :required => "required",
  :default => "jboss",
  :format => {
    :help => 'JBoss User',
    :category => '1.Global',
    :order => 3
  } 



attribute 'java_options',
  :description => "Java Options",
  :default => "-Xmx128M -Djava.awt.headless=true",
  :format => {
    :help => 'JVM command line options',
    :category => '2.Java',
    :order => 1
  }
  
recipe "status", "JBoss Status"
recipe "start", "Start JBoss"
recipe "stop", "Stop JBoss"
recipe "restart", "Restart JBoss"
recipe "repair", "Repair JBoss"
