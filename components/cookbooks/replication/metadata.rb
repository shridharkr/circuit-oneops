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
  :default => '3',
  :format => {
    :help => 'Number of replicas',
    :category => '1.Scale',
    :order => 1
  }

attribute 'nodes',
  :description => "Cluster Nodes",
  :grouping => 'bom',
  :data_type => "array",
  :format => {
    :help => 'List of cluster nodes/hosts used for the replication',
    :category => '2.Cluster',
    :order => 1
  }

attribute 'ports',
  :description => "PAT Ports",
  :grouping => 'bom',
  :data_type => "hash",
  :format => {
    :help => 'PAT Ports. Internal Port => External Port',
    :category => '2.Cluster',
    :order => 2
  }

recipe "repair", "Repair"
