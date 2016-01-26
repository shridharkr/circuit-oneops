#
# Cookbook Name:: cassandra
# Recipe:: config_directives
#
# Copyright 2015, @WalmartLabs.

require 'json'

ruby_block 'update_config_directives' do
  Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
  block do
    cfg = JSON.parse(node.workorder.rfcCi.ciAttributes.config_directives)
    yaml_file = '/opt/cassandra/conf/cassandra.yaml'
    Chef::Application.fatal!("Can't find the YAML config file - #{yaml_file} ") if !File.exists? yaml_file
    merge_conf_directives(yaml_file, cfg)
  end
  only_if { conf_directive_supported? }
end