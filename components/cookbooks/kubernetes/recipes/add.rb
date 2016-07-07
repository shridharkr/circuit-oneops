# Cookbook Name:: kubernetes
# Attributes:: add
#
# Author : OneOps
# Apache License, Version 2.0

# Wire util library to chef resources.
extend Kubernetes::Base
Chef::Resource::RubyBlock.send(:include, Kubernetes::Base)

# Check the platform
exit_with_err "Currently kubernetes is supported only on EL7 (RHEL/CentOS) or later." unless is_platform_supported?

if node.workorder.rfcCi.ciName.include?("-master")
  include_recipe "kubernetes::master"
else
  include_recipe "kubernetes::worker"  
end

log 'Kubernetes install/update completed!'
