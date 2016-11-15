name             "Container"
description      "Container spec"
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


# http://kubernetes.io/docs/user-guide/pods/multi-container/#containers

attribute 'image',
  :description => "Image Name",
  :format => {
    :help => 'Reference to an image name in the registry',
    :category => '1.Launch',
    :order => 1
  }

attribute 'command',
  :description => "Command",
  :format => {
    :help => 'Command to use as entrypoint to start the container',
    :category => '1.Launch',
    :order => 2
  }

attribute 'args',
  :description => "Arguments",
  :data_type => "array",
  :default => '[]',
  :format => {
    :help => 'Command arguments to use as entrypoint to start the container',
    :category => '1.Launch',
    :order => 3
  }

attribute 'env',
  :description => "Environment Variables",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => '',
    :category => '1.Launch',
    :order => 4
  }

attribute 'ports',
  :description => "Ports",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Map of port name (a DNS_LABEL) and value as <port-number>[/<port-protocol>]. Example ssh=22/tcp',
    :category => '1.Launch',
    :order => 5
  }

attribute 'cpu',
  :description => "CPU",
  :format => {
    :help => 'CPUs to reserve for each container. Default is whole CPUs; scale suffixes (e.g. 100m for one hundred milli-CPUs) are supported',
    :category => '2.Resources',
    :order => 1
  }

attribute 'memory',
  :description => "Memory",
  :format => {
    :help => 'Memory to reserve for each container. Default is bytes; binary scale suffixes (e.g. 100Mi for one hundred mebibytes) are supported',
    :category => '2.Resources',
    :order => 2
  }

recipe "repair", "Repair"
