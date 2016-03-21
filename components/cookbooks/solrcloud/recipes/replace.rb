#
# Cookbook Name:: solrcloud
# Recipe:: replace.rb
#
# This recipe replace the node and installs solrcloud and adds as the replica to solrcloud.
#
#

include_recipe "solrcloud3::default"
include_recipe "solrcloud3::solrcloud"
include_recipe "solrcloud3::deploy"
include_recipe "solrcloud3::customconfig"
include_recipe "solrcloud3::replacereplica"


