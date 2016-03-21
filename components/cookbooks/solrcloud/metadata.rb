name 'Solrcloud'
maintainer 'Forklift Team'
license 'none'
version '1.0.0'

grouping 'default',
  :access => 'global',
  :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


attribute 'solr_package_type',
  :description => 'Solr binary distribution package type ',
  :required => 'required',
  :default => 'solr',
  :format => {
    :help => 'Nexus formats of Solr binary distribution ',
    :category => '1.SolrCloud',
    :form => {'field' => 'select', 'options_for_select' => [['solr', 'solr']]},
    :order => 1
  }

attribute 'solr_version',
  :description => 'Solr binary distribution version',
  :required => 'required',
  :default => '4.10.3.2',
  :format => {
    :important => true,
    :help => 'Nexus version of Solr binary distribution ',
    :category => '1.SolrCloud',
    :form => {'field' => 'select', 'options_for_select' => [['4.10.3.2', '4.10.3.2'], ['4.10.3', '4.10.3'], ['5.0', '5.0']]},
    :order => 2
  }

attribute 'solr_format',
  :description => 'Solr binary distribution format (.tgz)/(.tar.gz)',
  :required => 'required',
  :default => 'tar.gz',
  :format => {
    :help => 'Nexus formats of Solr binary distribution ',
    :category => '1.SolrCloud',
    :form => {'field' => 'select', 'options_for_select' => [['tar.gz', 'tar.gz'], ['tar', 'tar'], ['war', 'war'], ['tgz', 'tgz']]},
    :order => 3
  }

attribute 'config_name',
  :description => 'Name of default Solr config',
  :default => '$OO_LOCAL{configname}',
  :format => {
    :help => 'Name of default Solr config',
    :category => '1.SolrCloud',
    :order => 4
  }

attribute 'custom_config_url',
  :description => 'Nexus URL of Custom Solr Config (.jar)',
  :format => {
    :help => 'Custom Solr Config Url in nexus',
    :category => '1.SolrCloud',
    :order => 5
  }

attribute 'custom_config_name',
  :description => 'Name of custom Solr Config',
  :format => {
    :help => 'Custom Prod Config Name',
    :category => '1.SolrCloud',
    :order => 6
  }

attribute 'deploy_all_dcs',
  :description => 'Deploy solrcloud and zookeeper in same DataCenter',
  :default => 'false',
  :format => {
    :help => 'Deploy solrcloud across ALL DataCenters',
    :category => '2.External Zookeeper',
    :form => { 'field' => 'checkbox' },
    :order => 7
  }

attribute 'zk_host_fqdns',
  :description => 'External Zookeeper connection string',
  :format => {
    :help => 'Zookeeper connect string in the following format. IP1:clientPort,IP2:clientPort',
    :category => '2.External Zookeeper',
    :order => 8
  }

attribute 'deploy_embed_zkp',
  :description => 'Deploy solrcloud using Embedded Zookeeper',
  :default => 'false',
  :format => {
    :help => 'Deploy solrcloud using Embedded Zookeeper',
    :category => '3.Embedded Zookeeper',
    :form => { 'field' => 'checkbox' },
    :order => 9
  }

attribute 'zkp_version',
  :description => 'Zookeeper binary distribution version',
  :required => 'required',
  :default => '3.4.6',
  :format => {
    :important => true,
    :help => 'Nexus version of Zookeeper binary distribution ',
    :category => '3.Embedded Zookeeper',
    :form => {'field' => 'select', 'options_for_select' => [['3.4.6', '3.4.6'], ['3.5.0', '3.5.0']]},
    :order => 10
  }

attribute 'zkp_format',
  :description => 'Zookeeper binary distribution format (.tgz)/(.tar.gz)',
  :required => 'required',
  :default => 'tar.gz',
  :format => {
    :help => 'Nexus formats of Zookeeper binary distribution ',
    :category => '3.Embedded Zookeeper',
    :form => {'field' => 'select', 'options_for_select' => [['tar.gz', 'tar.gz']]},
    :order => 11
  }

attribute 'num_local_instances',
  :description => 'Enter the no of local tomcat instances',
  :format => {
    :help => 'No of local tomcat instances',
    :category => '3.Embedded Zookeeper',
    :order => 12
  }

attribute 'http_port_nos',
  :description => 'Enter the list of http port nos for multiple tomcat instances.(Hint: Specify in comma seperated values)',
  :format => {
    :help => 'List of http port nos',
    :category => '3.Embedded Zookeeper',
    :order => 13
  }

attribute 'ssl_port_nos',
  :description => 'Enter the list of ssl port nos for multiple tomcat instances.(Hint: Specify in Comma seperated values)',
  :format => {
    :help => 'List of ssl port nos',
    :category => '3.Embedded Zookeeper',
    :order => 14
  }

attribute 'server_port_nos',
  :description => 'Enter the list of server port nos for multiple tomcat instances.(Hint: Specify in Comma seperated values)',
  :format => {
    :help => 'List of server port nos',
    :category => '3.Embedded Zookeeper',
    :order => 15
  }

attribute 'ajp_port_nos',
  :description => 'Enter the list of ajp port nos for multiple tomcat instances.(Hint: Specify in Comma seperated values)',
  :format => {
    :help => 'List of ajp port nos',
    :category => '3.Embedded Zookeeper',
    :order => 16
  }

attribute 'collection_name',
  :description => 'Enter the collection name to add replica, create/reload collection.',
  :default => '$OO_LOCAL{collectionname}',
  :format => {
    :help => 'Collection Name',
    :category => '4.SolrCloud Action Items',
    :order => 17
  }

attribute 'num_shards',
  :description => 'Enter the num shards to create collection. ',
  :default => '$OO_LOCAL{numshards}',
  :format => {
    :help => 'Number of Shards in the collection',
    :category => '4.SolrCloud Action Items',
    :order => 18
  }

attribute 'replication_factor',
  :description => 'Enter the replication factor to create collection. ',
  :default => '$OO_LOCAL{replicationfactor}',
  :format => {
    :help => 'Replication factor',
    :category => '4.SolrCloud Action Items',
    :order => 19
  }

attribute 'max_shards_per_node',
  :description => 'Enter the max shards per node to create collection. ',
  :default => '$OO_LOCAL{maxshardspernode}',
  :format => {
    :help => 'Maximum number of shards per node',
    :category => '4.SolrCloud Action Items',
    :order => 20
  }



recipe "delete", "Delete the solr specific directories"
recipe "update", "Update the solr cloud"
recipe "addreplica", "Add Replica To SolrCloud"
recipe "reloadcollection", "Reload Collection To SolrCloud"
recipe "createcollection", "Create Collection To SolrCloud"



