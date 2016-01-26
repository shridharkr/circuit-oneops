name             "Index"
description      "Index"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
maintainer       "OneOps"
version          "0.1"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'index_name',
  :description => "Index name",
  :default => "",
  :required => "required",
  :format => {
    :help => 'Name of the index',
    :category => '1.Index',
    :order => 1
  }
  
attribute 'json_mappings',
  :description => "Custom Mappings.",
  :default => "{}",
  :data_type => "hash",
  :format => {
    :help => 'Custom well-formed json mappings with key as index type.',
    :category => '1.Mappings',
    :order => 1
  }

