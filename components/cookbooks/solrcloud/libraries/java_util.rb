#
# Cookbook Name:: solrcloud
# Library:: java_util
#
# A utility module to deal with helper methods.
#
#

module Java

  module Util

    require 'json'

    include Chef::Mixin::ShellOut

    def downloadconfig(zkHost,configname)
      Chef::Log.info('Download prod config through zookeeper ZkCLI')
      begin
        bash 'download_config' do
          Chef::Log.info("java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd downconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/#{configname} -confname #{configname}")
          code <<-EOH
            java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd downconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/#{configname} -confname #{configname}
          EOH
          not_if { "#{configname}".empty? }
          ignore_failure true
        end
      rescue
        Chef::Log.error("Failed to download config. Config '#{configname}' may not exists.")
      else
        Chef::Log.info("Successfully downloaded config '#{configname}'")
      ensure
        puts "End of download_config execution."
      end
    end

    def uploadprodconfig(zkHost,configname)
      Chef::Log.info('Upload PROD config through zookeeper ZkCLI')
      begin
        bash 'upload_prod_config' do
          Chef::Log.info("Uploading config to zookeeper")
          code <<-EOH
            java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/prod -confname #{configname}
          EOH
          not_if { ::File.exists?("#{node['user']['dir']}/solr-config/#{configname}") }
        end
      rescue
        Chef::Log.error("Failed to upload config. Config '#{configname}' does not exists.")
      else
        Chef::Log.info("Successfully uploaded config '#{configname}'")
      ensure
        puts "End of upload_prod_config execution."
      end
    end

    def uploaddefaultconfig(zkHost,configname)
      Chef::Log.info('Upload PROD config through zookeeper ZkCLI')
      begin
        bash 'upload_default_config' do
          Chef::Log.info("Uploading config to zookeeper")
          Chef::Log.info("java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/default -confname #{configname}")
          code <<-EOH
            java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/default -confname #{configname}
          EOH
          not_if { ::File.exists?("#{node['user']['dir']}/solr-config/#{configname}") }
        end
      rescue
        Chef::Log.error("Failed to upload config. Config '#{configname}' does not exists.")
      else
        Chef::Log.info("Successfully uploaded config '#{configname}'")
      ensure
        puts "End of upload_default_config execution."
      end
    end



  end
end


