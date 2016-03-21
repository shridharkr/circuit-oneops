#
# Cookbook Name:: solrcloud
# Recipe:: add.rb
#
#
#
#

include_recipe "solrcloud::default"
include_recipe "solrcloud::solrcloud"
include_recipe "solrcloud::deploy"
include_recipe "solrcloud::customconfig"


