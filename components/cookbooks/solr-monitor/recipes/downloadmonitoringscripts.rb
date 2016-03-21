#
# Cookbook Name:: solr-monitor
# Recipe:: downloadscripts.rb
#
# This recipe downloads the scripts from nexus.
# @walmartlabs
#

extend Java::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, Java::Util)

ci = node.workorder.rfcCi.ciAttributes;

solrmon_pkg_type = ci[:solrmon_pkg_type]
solrmon_version = ci[:solrmon_version]
solrmon_format = ci[:solrmon_format]
solrmon_file_name = "#{solrmon_pkg_type}-#{solrmon_version}.#{solrmon_format}"

solrmonitoringscripts_url = getmirrorservice
solrmonitoringscripts_url = "#{solrmonitoringscripts_url}/#{solrmon_pkg_type}/#{solrmon_version}/#{solrmon_file_name}";


Chef::Log.info('Create Directory "scripts"')
directory "#{node['user']['dir']}/scripts" do
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0777'
  action :create
end

Chef::Log.info('Create Directory "#{solrmon_version}"')
directory "#{node['script']['dir']}/#{solrmon_version}" do
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0777'
  action :create
end

link "#{node['solr']['script_version']}" do
  to "#{node['script']['dir']}/#{solrmon_version}"
  link_type :symbolic
end

if !"#{solrmonitoringscripts_url}".empty?
  solrmonitoringscripts_url = solrmonitoringscripts_url.delete(' ');
  if !"#{solrmonitoringscripts_url}".empty?
    solrmonitoringscripts_tar_gz = "#{solrmonitoringscripts_url}".split("/").last.split(".tar.gz").first+".tar.gz";
    solrmonitoringscripts_tar = "#{solrmonitoringscripts_tar_gz}".split(".tar").first+".tar";
    Chef::Log.info("#{solrmonitoringscripts_tar_gz}")
    Chef::Log.info("#{solrmonitoringscripts_tar}")
  else
  	Chef::Log.info(" solrmonitoringscripts url is empty ")
  end
else
  Chef::Log.info(" solrmonitoringscripts url is empty ")
end


if "#{solrmonitoringscripts_tar_gz}".empty?
  Chef::Log.info(" solrmonitoringscripts tar file name is not provided ")
else
  Chef::Log.info("Download solr monitoring scripts : #{solrmonitoringscripts_tar_gz} : from gec-nexus")
  remote_file "#{node['solr']['script_version']}/"+"#{solrmonitoringscripts_tar_gz}" do
    source "#{solrmonitoringscripts_url}"
    owner "#{node['solr']['user']}"
    group "#{node['solr']['user']}"
    mode '0644'
    action :create_if_missing
  end
end

Chef::Log.info('Unpack and Deploy monitoring scripts')
bash 'deploy_solr_monitoring_scripts' do
  code <<-EOH
    cd "#{node['solr']['script_version']}"
    gunzip #{solrmonitoringscripts_tar_gz}
    mkdir #{node['monitor']['dir']}
    chown #{node['solr']['user']}:#{node['solr']['user']} #{node['monitor']['dir']}/*
    cp #{solrmonitoringscripts_tar} #{node['monitor']['dir']}/
    cd #{node['monitor']['dir']}
    tar -xvf #{solrmonitoringscripts_tar}
    rm -rf #{solrmonitoringscripts_tar}
    cd "#{node['script']['dir']}"
    sudo rm -rf solr-monitor-*.txt
    echo #{solrmon_version} > solr-monitor-scripts-#{solrmon_version}.txt
  EOH
  not_if { ::File.exists?("#{node['script']['dir']}/solr-monitor-scripts-#{solrmon_version}.txt") }
end




