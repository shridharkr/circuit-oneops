name 'Solrcloud'
license 'Apache License, Version 2.0'
version '1.0.0'

grouping 'default',
  :access => 'global',
  :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'solr_url',
  :description => 'Solr binary distribution base url',
  :required => 'required',
  :default => '$OO_CLOUD{nexus}/nexus/content/groups/public/org/apache/solr',
  :format => {
    :help => 'Nexus version of Solr binary distribution ',
    :category => '1.SolrCloud',
    :order => 1
  }

attribute 'solr_package_type',
  :description => 'Solr binary distribution package type ',
  :required => 'required',
  :default => 'solr',
  :format => {
    :help => 'Nexus formats of Solr binary distribution ',
    :category => '1.SolrCloud',
    :form => {'field' => 'select', 'options_for_select' => [['solr', 'solr']]},
    :order => 2
  }

attribute 'solr_format',
  :description => 'Solr binary distribution format (.tgz)/(.tar.gz)',
  :required => 'required',
  :default => 'tgz',
  :format => {
    :help => 'Nexus formats of Solr binary distribution ',
    :category => '1.SolrCloud',
    :form => {'field' => 'select', 'options_for_select' => [['tgz', 'tgz'],['tar.gz', 'tar.gz']]},
    :order => 3
  }

attribute 'solr_version',
  :description => 'Solr binary distribution version',
  :required => 'required',
  :default => '4.10.3.2',
  :format => {
    :help => 'Nexus version of Solr binary distribution ',
    :category => '1.SolrCloud',
    :form => {'field' => 'select', 'options_for_select' => [['4.10.3', '4.10.3'],['4.10.3.2', '4.10.3.2'],['5.0.0', '5.0.0'],['5.1.0', '5.1.0'],['5.2.0', '5.2.0'],['5.2.1', '5.2.1'],['5.3.0', '5.3.0'],['5.3.1', '5.3.1'],['5.3.2', '5.3.2'],['5.4.0', '5.4.0'],['5.4.1', '5.4.1'],['5.5.0', '5.5.0'],['5.5.1', '5.5.1'],['6.0.0', '6.0.0']]},
    :order => 4
  }

attribute 'replace_nodes',
  :description => "Add all of the replaced nodes to the old collection",
  :default => "false",
  :format => {
    :category => '1.SolrCloud',
    :filter => {'all' => {'visible' => 'solr_version:eq:4.10.3.2 || solr_version:eq:4.10.3'}},
    :order => 5,
    :form => {'field' => 'checkbox'}
  }

attribute 'config_name',
  :description => 'Name of default Solr config',
  :default => 'defaultconf',
  :format => {
    :help => 'Name of default Solr config',
    :category => '1.SolrCloud',
    :order => 6
  }

attribute 'custom_config_url',
  :description => 'Nexus URL of Custom Solr Config (.jar)',
  :default => 'customconfigurl',
  :format => {
    :help => 'Custom Solr Config Url in nexus',
    :category => '1.SolrCloud',
    :order => 7
  }

attribute 'custom_config_name',
  :description => 'Name of custom Solr Config',
  :default => 'customconfigname',
  :format => {
    :help => 'Custom Prod Config Name',
    :category => '1.SolrCloud',
    :order => 8
  }

attribute 'installation_dir_path',
  :description => 'installation directory',
  :default => '/app',
  :format => {
    :help => 'installation directory',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 9
  }

attribute 'data_dir_path',
  :description => 'data directory',
  :default => '/app/solrdata',
  :format => {
    :help => 'data directory',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 10
  }

attribute 'port_no',
  :description => 'port no',
  :default => '8983',
  :format => {
    :help => 'port no',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 11
  }

attribute 'gc_tune_params',
  :description => 'GC TUNE params',
  :data_type => 'array',
  :default => '["NewRatio=3"]',
  :format => {
    :help => 'GC_TUNE_params',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 12
  }

attribute 'gc_log_params',
  :description => 'GC LOG params',
  :data_type => 'array',
  :default => '["-verbose:gc"]',
  :format => {
    :help => 'GC_LOG_params',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 13
  }

attribute 'solr_opts_params',
  :description => 'SOLROPTS params',
  :data_type => 'array',
  :default => '["solr.autoSoftCommit.maxTime=3000"]',
  :format => {
    :help => 'SOLR_OPTS_params',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 14
  }

attribute 'solr_max_heap',
  :description => 'solr max heap',
  :default => '-Xmx512m',
  :format => {
    :help => 'solr_max_heap',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 15
  }

attribute 'solr_min_heap',
  :description => 'solr min heap',
  :default => '-Xms512m',
  :format => {
    :help => 'solr_min_heap',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 16
  }

attribute 'zk_select',
  :description => 'Internal/External/Embedded',
  :required => 'required',
  :default => 'External',
  :format => {
      :help => 'Internal/External/Embedded',
      :category => '3.Zookeeper',
      :order => 17,
      :form => {'field' => 'select', 'options_for_select' => [['ExternalEnsemble', 'ExternalEnsemble'],['InternalEnsemble-SameAssembly', 'InternalEnsemble-SameAssembly'],['Embedded', 'Embedded']]}
  }

attribute 'zk_host_fqdns',
  :description => 'External ZK hosts',
  :default => 'zk_host_fqdns',
  :format => {
      :help => "Location of External ZK hosts",
      :category => '3.Zookeeper',
      :filter => {'all' => {"visible" => "zk_select:eq:ExternalEnsemble"}},
      :order => 18
  }

attribute 'num_instances',
  :description => 'num_instances',
  :default => '1',
  :format => {
    :help => 'num_instances',
    :category => '3.Zookeeper',
    :filter => {'all' => {"visible" => "zk_select:eq:Embedded"}},
    :order => 19
  }

attribute 'port_num_list',
  :description => 'Port nos list',
  :default => '8080',
  :format => {
    :help => 'Port num list',
    :category => '3.Zookeeper',
    :filter => {'all' => {"visible" => "zk_select:eq:Embedded"}},
    :order => 20
  }

attribute 'platform_name',
  :description => 'Platform Name',
  :default => 'zookeeper',
  :format => {
    :help => 'Platform Name',
    :category => '3.Zookeeper',
    :filter => {'all' => {"visible" => "zk_select:eq:InternalEnsemble-SameAssembly"}},
    :order => 21
  }

# attribute 'memberid',
#   :description => 'Member Id',
#   :grouping => 'bom',
#   :format => {
#       :help => 'Unique Id of the Etcd member',
#       :important => true,
#       :category => '4.Identity',
#       :order => 24
#   }


recipe "addreplica",
  :description => 'Adds Replica To Collection',
  :args => {
    "PhysicalCollectionName" => {
      "name" => "PhysicalCollectionName",
      "description" => "Adds as a replica to the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "ShardName" => {
      "name" => "ShardName",
      "description" => "Shard of a collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    }
  }

recipe "reloadcollection",
  :description => 'Reloads Collection',
  :args => {
    "PhysicalCollectionName" => {
      "name" => "PhysicalCollectionName",
      "description" => "Reloads the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    }
  }

recipe "createcollection",
  :description => 'Creates Collection',
  :args => {
    "PhysicalCollectionName" => {
      "name" => "PhysicalCollectionName",
      "description" => "Creates the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "NumberOfShards" => {
      "name" => "NumberOfShards",
      "description" => "Number of shards in the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "ReplicationFactor" => {
      "name" => "ReplicationFactor",
      "description" => "Replication Factor for the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "MaxShardsPerNode" => {
      "name" => "MaxShardsPerNode",
      "description" => "Max shards per node in the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "ConfigName" => {
      "name" => "ConfigName",
      "description" => "ConfigName to create the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    }
  }


recipe "modifycollection",
  :description => 'Modifies Collection',
  :args => {
    "PhysicalCollectionName" => {
      "name" => "PhysicalCollectionName",
      "description" => "Modifies the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "AutoAddReplicas" => {
      "name" => "PhysicalCollectionName",
      "description" => "Modifies the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "ReplicationFactor" => {
      "name" => "ReplicationFactor",
      "description" => "Replication Factor for the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "MaxShardsPerNode" => {
      "name" => "MaxShardsPerNode",
      "description" => "Max shards per node in the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    }
  }

recipe "deletecollection",
  :description => 'Delete Collection',
  :args => {
    "PhysicalCollectionName" => {
      "name" => "PhysicalCollectionName",
      "description" => "Delete the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    }
  }

recipe "uploadsolrconfig",
  :description => 'Uploads solr config to zookeeper',
  :args => {
    "CustomConfigJar" => {
      "name" => "CustomConfigJar",
      "description" => "CustomConfigJar",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "CustomConfigName" => {
      "name" => "CustomConfigName",
      "description" => "CustomConfigName",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    }
  }


recipe "status", "Solr Status"
recipe "start", "Start Solr"
recipe "stop", "Stop Solr"
recipe "restart", "Restart Solr"
# recipe "delete", "Deletes all the files and directories"
recipe "updateclusterstate", "Deletes all the dead/down replicas and update cluster state"

