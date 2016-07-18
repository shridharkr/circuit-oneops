#
# Cookbook Name :: solrcloud
# Recipe :: addReplica.rb
#
# The recipe deleted the collection on the solrcloud.
#

include_recipe 'solrcloud::default'

extend SolrCloud::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)


args = ::JSON.parse(node.workorder.arglist)
collection_name = args["PhysicalCollectionName"]


deleteCollection(node['solr_collection_url'],"#{collection_name}")


