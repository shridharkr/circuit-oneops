name 'Solrcloud'
license 'Apache License, Version 2.0'
version '1.0.0'

grouping 'default',
  :access => 'global',
  :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'solr_url',
  :description => 'Solr binary distribution version',
  :required => 'required',
  :default => 'https://archive.apache.org/dist/lucene',
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

attribute 'solr_version',
  :description => 'Solr binary distribution version',
  :required => 'required',
  :default => '4.10.3',
  :format => {
    :help => 'Nexus version of Solr binary distribution ',
    :category => '1.SolrCloud',
    :order => 3
  }

attribute 'solr_format',
  :description => 'Solr binary distribution format (.tgz)/(.tar.gz)',
  :required => 'required',
  :default => 'tgz',
  :format => {
    :help => 'Nexus formats of Solr binary distribution ',
    :category => '1.SolrCloud',
    :form => {'field' => 'select', 'options_for_select' => [['tgz', 'tgz'],['tar.gz', 'tar.gz']]},
    :order => 4
  }

attribute 'config_name',
  :description => 'Name of default Solr config',
  :default => 'defaultconf',
  :format => {
    :help => 'Name of default Solr config',
    :category => '1.SolrCloud',
    :order => 5
  }

attribute 'custom_config_url',
  :description => 'Nexus URL of Custom Solr Config (.jar)',
  :format => {
    :help => 'Custom Solr Config Url in nexus',
    :category => '1.SolrCloud',
    :order => 6
  }

attribute 'custom_config_name',
  :description => 'Name of custom Solr Config',
  :format => {
    :help => 'Custom Prod Config Name',
    :category => '1.SolrCloud',
    :order => 7
  }

attribute 'collection_name',
  :required => 'required',
  :description => 'collection name',
  :default => 'test'
  :format => {
    :help => 'collection name',
    :category => '1.SolrCloud',
    :order => 8
  }

attribute 'zk_select',
  :description => 'External',
  :required => 'required',
  :default => 'External',
  :format => {
      :help => 'External',
      :category => '2.Zookeeper',
      :order => 9,
      :form => {'field' => 'select', 'options_for_select' => [['External', 'External']]}
  }

attribute 'zk_host_fqdns',
  :description => 'External ZK hosts',
  :format => {
      :help => "Location of External ZK hosts",
      :category => '2.Zookeeper',
      :filter => {'all' => {'visible' => 'zk_select:eq:External'}},
      :order => 10
  }


recipe "addreplica",
  :description => 'Adds Replica To Collection',
  :args => {
    "PhysicalCollectionName" => {
      "name" => "PhysicalCollectionName",
      "description" => "Adds as a replica to the collection",
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
    }
  }



