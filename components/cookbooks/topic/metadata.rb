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
  :description => "Topic Name",
  :required => "required",
  :default => 'test',
  :format => {
    :important => true,
    :help => 'Name of the Topic',
    :category => '1.General',
    :order => 1
  }

recipe "repair", "Repair Topic"
