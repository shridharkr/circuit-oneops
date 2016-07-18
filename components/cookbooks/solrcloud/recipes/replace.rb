#
# Cookbook Name :: solrcloud
# Recipe :: replace.rb
#
# The recipe sets up the solrcloud on the replaced node.
#

include_recipe 'solrcloud::default'

include_recipe 'solrcloud::solrcloud'
include_recipe 'solrcloud::deploy'
include_recipe 'solrcloud::customconfig'


execute "tomcat#{node['tomcatversion']} restart" do
    command "service tomcat#{node['tomcatversion']} restart"
    user "#{node['solr']['user']}"
    action :run
    only_if { ::File.exists?("/etc/init.d/tomcat#{node['tomcatversion']}")}
end


include_recipe "solrcloud::replacereplica"

