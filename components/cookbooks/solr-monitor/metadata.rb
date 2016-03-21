name             'Solr-monitor'
maintainer       'forklift search'
license          'All rights reserved'
version          '1.0.0'


grouping 'default',
  :access => 'global',
  :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


attribute 'solrmon_pkg_type',
  :description => 'Solr monitor sciripts binary distribution package type ',
  :required => 'required',
  :default => 'solr-monitoring',
  :format => {
    :help => 'Nexus package type of Solr monitor scripts binary distribution ',
    :category => '1.SolrMonitoring',
    :form => {'field' => 'select', 'options_for_select' => [['solr-monitoring', 'solr-monitoring']]},
    :order => 1
  }

attribute 'solrmon_version',
  :description => 'Solr monitor scripts binary distribution version',
  :required => 'required',
  :default => '1.1',
  :format => {
    :important => true,
    :help => 'Nexus version of Solr monitor scripts binary distribution ',
    :category => '1.SolrMonitoring',
    :form => {'field' => 'select', 'options_for_select' => [['1.1', '1.1'], ['1.2', '1.2'],['1.3', '1.3'],['1.4', '1.4']]},
    :order => 2
  }

attribute 'solrmon_format',
  :description => 'Solr monitor scripts binary distribution format (.tar.gz)',
  :required => 'required',
  :default => 'tar.gz',
  :format => {
    :help => 'Nexus formats of Solr monitor scripts binary distribution ',
    :category => '1.SolrMonitoring',
    :form => {'field' => 'select', 'options_for_select' => [['tar.gz', 'tar.gz']]},
    :order => 3
  }

attribute 'graphite_server',
  :description => 'Graphite Server',
  :required => 'required',
  :default => 'esm-graphite.prod.walmart.com',
  :format => {
    :help => 'graphite server',
    :category => '1.SolrMonitoring',
    :order => 4
  }

attribute 'graphite_port',
  :description => 'Graphite Port',
  :required => 'required',
  :default => '2003',
  :format => {
    :help => 'graphite port',
    :category => '1.SolrMonitoring',
    :order => 5
  }

attribute 'email_addresses',
  :description => 'Email Addresses',
  :required => 'required',
  :default => '$OO_LOCAL{emailaddresses}',
  :format => {
    :help => 'App Name',
    :category => '1.SolrMonitoring',
    :order => 6
  }

attribute 'logical_collection_name',
  :description => 'Logical Collection Name',
  :required => 'required',
  :default => '$OO_LOCAL{logicalcollectionname}',
  :format => {
    :help => 'Collection Name',
    :category => '2.Dashboard',
    :order => 7
  }

attribute 'app_name',
  :description => 'App Name',
  :required => 'required',
  :default => '$OO_LOCAL{appname}',
  :format => {
    :help => 'App Name',
    :category => '2.Dashboard',
    :order => 8
  }

attribute 'solrcloud_datacenter',
  :description => 'SolrCloud DataCenter',
  :required => 'required',
  :default => '$OO_LOCAL{solrclouddatacenter}',
  :format => {
    :help => 'SolrCloud Datacenter Name',
    :category => '2.Dashboard',
    :order => 9
  }

attribute 'solrcloud_env',
  :description => 'SolrCloud Environment',
  :required => 'required',
  :default => '$OO_LOCAL{solrcloudenv}',
  :format => {
    :help => 'SolrCloud Environment',
    :category => '2.Dashboard',
    :order => 10
  }



recipe "setupBasicDashboard", "Create Basic Dashboard"
recipe "delete", "Delete directories/files"


