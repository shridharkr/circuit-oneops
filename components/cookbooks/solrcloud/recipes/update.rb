#
# Cookbook Name:: solrcloud
# Recipe:: update.rb
#
# This recipe updates the solrcloud installation.
#
#

include_recipe "solrcloud::solrcloud"
include_recipe "solrcloud::deploy"
include_recipe "solrcloud::customconfig"


