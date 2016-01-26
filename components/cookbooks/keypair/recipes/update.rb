#
# Cookbook Name:: keypair
# Recipe:: update
#

include_recipe "keypair::delete"
include_recipe "keypair::add"

