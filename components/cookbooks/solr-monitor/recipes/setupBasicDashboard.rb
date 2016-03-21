#
# Cookbook Name:: solr-monitor
# Recipe:: setupDashboard.rb
#
# This recipe creates the basic dashboard.
# @walmartlabs
#

require 'set'
require 'open-uri'
require 'json'
require 'uri'

ci = node.workorder.ci.ciAttributes;
app_name = ci[:app_name]
solrcloud_env = ci[:solrcloud_env]
solrcloud_datacenter = ci[:solrcloud_datacenter]

logical_cname_list = ci[:logical_collection_name]

solr_monitor_version = ci[:solrmon_version]

request_url = "http://#{node['ipaddress']}:8080/"+"#{node['clusterstatus']['uri']}"
Chef::Log.info("#{request_url}")

response = open(request_url).read
jsonresponse = JSON.parse(response)

if File.file?("#{node['script']['dir']}/dashboard-#{solr_monitor_version}.txt")
  Chef::Log.info('#{solr_monitor_version} dashboard script exists')
  bash 'cleanuptorecreate' do
    code <<-EOH
      cd "#{node['script']['dir']}"
      rm -rf dashboard-#{solr_monitor_version}.txt
    EOH
  end
end

aliasList = jsonresponse["cluster"]["aliases"];
if !"#{aliasList}".empty?
  aliasList = aliasList.keys
else
  raise "Aliases are empty."
end

if "#{logical_cname_list}".empty?
  raise "Logical alias names are empty in the input."
end

logical_cnames = logical_cname_list.split(",")
logical_cnames.each do |lcname|
  if aliasList.include? "#{lcname}"
    pcname = jsonresponse["cluster"]["aliases"]["#{lcname}"]

    set = Set.new;
    if !"#{pcname}".empty?
      Chef::Log.info('Creating dasboard scripts for #{solr_monitor_version} monitor scripts ')
      if !jsonresponse["cluster"]["collections"].empty? && !jsonresponse["cluster"]["collections"]["#{pcname}"].empty?
        shardList = jsonresponse["cluster"]["collections"]["#{pcname}"]["shards"].keys
        replicaip = '';
        shardList.each do |shard|
        replicaList = jsonresponse["cluster"]["collections"]["#{pcname}"]["shards"][shard]["replicas"].keys
          replicaList.each do |replica|
            replicaip = replica.split(":")[0]
            unless set.add?( replicaip )
              set.add(replicaip)
            end
          end
        end
      else
        raise "Cluster State is empty for the given alias collection '#{lcname}' . Failed to create dashboard."
      end
    end

    set.each do |key|
      bash 'createipAddressFile' do
        code <<-EOH
          cd "#{node['user']['dir']}"
          echo '#{key}' >> #{node['monitor']['dir']}/ipAddress.txt
        EOH
      end
    end

    Chef::Log.info('Setup Dashboard')
    bash 'setupDashboard' do
      Chef::Log.info("#{node['dashboardscript']['dir']}/createDashboard.sh #{node['monitor']['dir']}/ipAddress.txt #{app_name} #{lcname} #{solrcloud_env} #{solrcloud_datacenter}")
      code <<-EOH
        cd #{node['user']['dir']}
        sh #{node['dashboardscript']['dir']}/createDashboard.sh #{node['monitor']['dir']}/ipAddress.txt #{app_name} #{lcname} #{solrcloud_env} #{solrcloud_datacenter}
      EOH
    end
  else
    raise "Alias/logical name '#{lcname}' is not available in the solrcloud alias list [ #{aliasList} ].Could not create dashboard."
  end
  bash 'cleanuptorecreate' do
    code <<-EOH
      cd "#{node['monitor']['dir']}"
      rm -rf #{node['monitor']['dir']}/ipAddress.txt
    EOH
  end
end




