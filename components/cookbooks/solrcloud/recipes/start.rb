#
# Cookbook Name :: solrcloud
# Recipe :: start.rb
#
# The recipe starts the solrcloud on the node.
#

ci = node.workorder.ci.ciAttributes;
solr_version = ci['solr_version']
solrmajorversion = "#{solr_version}"[0,1]


if "#{solr_version}".start_with? "4."
	execute "tomcat#{node['tomcatversion']} start" do
	  command "service tomcat#{node['tomcatversion']} start"
	  user node['solr']['user']
	  action :run
	  only_if { ::File.exists?("/etc/init.d/tomcat#{node['tomcatversion']}")}
	end
end

if ("#{solr_version}".start_with? "5.") || ("#{solr_version}".start_with? "6.")
	execute "solr#{solrmajorversion} start" do
	  command "service solr#{solrmajorversion} start"
	  user "root"
	  action :run
	  only_if { ::File.exists?("/etc/init.d/solr#{solrmajorversion}")}
	end
end


