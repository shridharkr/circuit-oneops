#
# Cookbook Name:: solrcloud
# Recipe:: replace.rb
#
# This recipe replace the node and installs solrcloud and adds as the replica to solrcloud.
#
#

include_recipe "solrcloud::default"
include_recipe "solrcloud::solrcloud"
include_recipe "solrcloud::deploy"
include_recipe "solrcloud::customconfig"
include_recipe "solrcloud::replacereplica"


