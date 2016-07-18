# A utility module for etcd.
#
# Cookbook Name:: etcd
# Library:: etcd_util
#
# Author : OneOps
# Apache License, Version 2.0

module Etcd

  module Util

    require 'json'
    require 'uri'
    include Chef::Mixin::ShellOut

    # Checks whether the platform is supported to install etcd.
    # Supports only EL7 (CentOS/RHEL) with kernel version 3.10.x
    # or later.
    #
    # @return : true if the platform is supported for etcd.
    #
    def is_platform_supported?
      plf = node.platform_family.downcase
      ver = node.platform_version.to_i
      Chef::Log.info "Checking platform support. Platform: #{plf}, version: #{ver}"
      plf == 'rhel' && ver >= 7
    end

    # Checks if the given package is available from the OS repo to install.
    #
    # @param pkg_name linux package name
    # @param version package version
    #
    # @return true if the  package is available.
    #
    def is_pkg_avail?(pkg_name, version)

      return false unless is_platform_supported?

      script = "yum list available #{pkg_name}-#{version}"
      Chef::Log.info "Checking the package: #{script}"
      cmd = shell_out(script, :live_stream => Chef::Log)
      Chef::Log.info "Exit status: #{cmd.exitstatus}. The #{pkg_name}-#{version} " +
                         "package is #{cmd.exitstatus != 0 ? 'NOT' : '' } available " +
                         'to install from OS repo.'
      cmd.exitstatus == 0
    end

    # Returns mirror url for the given service. Will first look into
    # the component attributes for mirror url and then in the cloud
    # mirror service if it's empty.
    #
    # @param name mirror service name
    # @return service url
    #
    def get_mirror_svc(name)
      cloud = node.workorder.cloud.ciName
      cookbook = node.app_name.downcase

      svc_url = node[cookbook][:mirror]
      Chef::Log.info("Component mirror url for #{cookbook} is #{svc_url.nil? ? 'not configured.' : svc_url}")
      return svc_url if (!svc_url.nil? && !svc_url.empty?)

      Chef::Log.info("Getting #{cloud} cloud mirror service for #{cookbook}")
      mirror_svc = node[:workorder][:services][:mirror]
      mirror = JSON.parse(mirror_svc[cloud][:ciAttributes][:mirrors]) unless mirror_svc.nil?

      # Search for service. If it can't find, use the default release url.
      (!mirror.nil? && mirror.has_key?(name)) ? mirror[name] : node.etcd.release_url
    end

    # Returns pkg download location for the given cookbook artifact.
    # The base url is formed based on the cookbook mirror service.
    #
    # @param cookbook - cookbook name.
    #
    # @returns : 2-Tuple (baseurl, filename)
    #            Base URL - Package base url
    #            File name - Package file name to download
    #
    def get_pkg_location(cookbook)

      version = node.etcd.version
      base_url = get_mirror_svc('etcd')
      Chef::Log.info("Etcd base_url: #{base_url}")

      # Replace any $version/$arch/$extn placeholder variables present in the URL
      # e.x: https://github.com/coreos/etcd/releases/download/v$version/etcd-v$version-$arch.$extn
      base_url = base_url.gsub('$version', version)
                     .gsub('$arch', node.etcd.arch)
                     .gsub('$extn', node.etcd.extn)
      exit_with_err("Invalid package base URL: #{base_url}") unless url_valid?(base_url)

      file_name = File.basename(URI.parse(base_url).path)
      Chef::Log.info("Package url: #{base_url}, filename: #{file_name}")
      return File.dirname(base_url), file_name

    end

    # Checks if the given string is a valid http/https URL
    #
    # @param - URL string to check
    def url_valid?(url)
      url = URI.parse(url) rescue false
      url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS)
    end


    # Exit the chef application process with the given error message
    #
    # @param : msg -  Error message
    #
    def exit_with_err(msg)
      Chef::Log.error(msg)
      puts "***FAULT:FATAL=#{msg}"
      Chef::Application.fatal!(msg)
    end

  end

end
