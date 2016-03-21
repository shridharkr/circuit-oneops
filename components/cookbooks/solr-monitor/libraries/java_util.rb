#
# Cookbook Name:: solr-monitor
# Library:: java_util
#
# A utility module to deal with helper methods.
# @walmartlabs
#

module Java

  module Util

    require 'json'

    include Chef::Mixin::ShellOut

    def getmirrorservice
      cloud = node.workorder.cloud.ciName
      cookbook = node.app_name.downcase
      Chef::Log.info("Getting mirror service for #{cookbook}, cloud: #{cloud}")
      mirror_svc = node[:workorder][:services][:mirror]
      mirror = JSON.parse(mirror_svc[cloud][:ciAttributes][:mirrors]) if !mirror_svc.nil?
      base_url = ''
      # Search for solr mirror
      base_url = mirror['solr-monitor'] if !mirror.nil? && mirror.has_key?('solr-monitor')

      if base_url.empty?
        # Search for cookbook default nexus mirror.
        Chef::Log.info('SolrMonitor mirror is empty. Using the default nexus mirror.')
        base_url = node[cookbook][:src_mirror] if base_url.empty?
      end

      return base_url
    end



  end
end


