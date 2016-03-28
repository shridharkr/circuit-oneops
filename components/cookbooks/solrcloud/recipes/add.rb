#
# Cookbook Name:: solrcloud
# Recipe:: add.rb
#
#
#
#

include_recipe "solrcloud::solrcloud"
include_recipe "solrcloud::deploy"
include_recipe "solrcloud::customconfig"
include_recipe "solrcloud::localinstances"

