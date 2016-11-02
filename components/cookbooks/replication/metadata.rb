name             "Replication"
description      "Container Replication"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => [ 'bom' ]

     
attribute 'replicas',
  :description => "Replicas",
  :format => {
    :help => 'Number of replicas',
    :category => '1.Scale',
    :order => 1
  }

recipe "repair", "Repair"
