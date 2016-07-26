# Cookbook Name:: etcd
# Attributes:: replace
#
# Author : OneOps
# Apache License, Version 2.0


include_recipe 'etcd::delete'
include_recipe 'etcd::register_new_node'
include_recipe 'etcd::add'
