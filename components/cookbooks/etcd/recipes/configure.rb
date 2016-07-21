# Cookbook Name:: etcd
# Attributes:: configure
#
# Author : OneOps
# Apache License, Version 2.0

# Get all the required computes
require 'uri'
require 'net/http'

# wire util library to chef resources.
extend Etcd::Util
Chef::Resource::RubyBlock.send(:include, Etcd::Util)

if node.workorder.payLoad.has_key?(:computes)
  computes = node.workorder.payLoad.computes
else
  computes = node.workorder.payLoad.RequiresComputes
end

# Get the local compute
local_server_ip = node.workorder.payLoad.ManagedVia[0]['ciAttributes']['private_ip']
local_server_name = node.workorder.payLoad.ManagedVia[0]['ciName']

primary_cloud = false

if node.workorder.cloud.ciAttributes.has_key?("priority") &&
    node.workorder.cloud.ciAttributes.priority == "1"
  primary_cloud = true
end

Chef::Log.info("rfcAction: #{node.workorder.rfcCi.rfcAction}")

etcd_cluster = Array.new
# Get etcd members

if primary_cloud == true
    Chef::Log.info("In primary clouds")
    #if node.workorder.rfcCi.rfcAction =~ /add/
      computes.each do |c, index|
        if c.ciAttributes.has_key?("private_ip") && c.ciAttributes.private_ip != nil
          etcd_cluster.push("#{c.ciName}=http://#{c.ciAttributes.private_ip}:2380")
        end
      end
      #else
      #  Chef::Log.info("TODO: implement other rfcAction other than 'add'")
      #end
else
# Assume that the nodes from secondary clouds will form a new Etcd cluster, which is
# independet of the Etcd cluster in primary clouds.

# The goal of the following method is to identify which IPs belong to secondary clouds.
# It assumes that nodes in secondary clouds could access the primary Etcd by CURL.
# For now, since FQDN always maps to the nodes in primary clouds and nodes do not
# communicate with each other directly about who is from primary clouds, we could let
# nodes in secondary clouds to take advantage of FQDN to ask who are the members of
# primary Etcd cluster by a CURL.

# For example:
#
# curl -L http://fqdn_url:2379/v2/members

# The response is JSON object which contains the Etcd members in primary Etcd cluster:
#
# {"members":[{"id":"14ae5702cb4236f9","name":"compute-238213-2","peerURLs":
# ["http://10.65.227.132:2380"],"clientURLs":["http://10.65.227.132:2379"]},
# {"id":"656b212b423387e4","name":"compute-238213-1","peerURLs":["http://10.65.226.26:2380"],
# "clientURLs":["http://10.65.226.26:2379"]}]}
#
# By removing the above returned IPs from workorder.PayLoad.computes, the remaining IPs should
# belong to secondary clouds.

# Note: there may be some assumptions for above apporach:
# 1. Etcd component has to depend on "hostname" component with PTR enabled.
# 2. Etcd in primary clouds is in working state
# 3. all Etcd nodes in primary clouds are functioning correctly

  # get FQDN by the dependency relationship from Etcd to FQDN
  require 'json'
  Chef::Log.info("secondary clouds...")
  full_hostname = `host #{node[:ipaddress]} | awk '{ print $NF }' | sed 's/.$//'`.strip
  Chef::Log.info("full_hostname: #{full_hostname}")
  while true
    if full_hostname =~ /NXDOMAIN/
      Chef::Log.info("Unable to resolve instance-level FQDN from IP by PTR, sleep 5s and retry: #{node[:ipaddress]}")
      sleep(5)
      full_hostname = `host #{node[:ipaddress]} | awk '{ print $NF }' | sed 's/.$//'`.strip
    else
      break;
    end
  end
  
  # full_hostname from PTR is the cloud-level and instance-level FQDN
  # but we need to use platform-level FQDN to connect to the Etcd running in primary clouds
  # the temp solution is to:
  # (1) drop the short hostname
  # (2) drop cloud info (e.g. dfwiaas4) from cloud-level FQDN
  # (3) add the platform name in front
  arr = full_hostname.split(".")[1..-1]
  arr.delete_at(3)
  platform_name = node.workorder.box.ciName
  # concat to get platform-level FQDN
  platform_fqdn = [platform_name, arr.join(".")].join(".")
  
  Chef::Log.info("platform_fqdn: #{platform_fqdn}")
  
  json_members = get_etcd_members_http(platform_fqdn)
  Chef::Log.info("json_members: "+JSON.parse(json_members).inspect.gsub("\n"," "))
  
  primary_hosts = Array.new
  members = JSON.parse(json_members)["members"]
  
  # make sure the number of Etcd members returned from HTTP call is half of number of all computes
  if members.length != (computes.length / 2)
    msg = "Number of Etcd members #(members.length) returned from HTTP call is NOT half of number of all computes #{computes.length}."
    Chef::Log.error(msg)
    puts "***FAULT:FATAL= #{msg}"
    e = Exception.new('no backtrace')
    e.set_backtrace('')
    raise e
  end
  
  members.each do |m|
    url = m["peerURLs"][0]
    Chef::Log.info("member url is: #{url}")
    host = URI.parse(url).host
    primary_hosts.push(host)
  end
  
  computes.each do |c, index|
    if c.ciAttributes.has_key?("private_ip") && !primary_hosts.include?(c.ciAttributes.private_ip)
      etcd_cluster.push("#{c.ciName}=http://#{c.ciAttributes.private_ip}:2380")
    end
  end
  
end

if node.etcd.security_enabled == 'true'
  protocol = 'https'
  exit_with_err 'server security certificate is empty.' if node.etcd.security_certificate.empty?
  exit_with_err 'server security key is empty.' if node.etcd.security_key.empty?
  exit_with_err 'certificate authority CA certificate is empty.' if node.etcd.security_ca_certificate.empty?

  directory node.etcd.security_path

  file "#{node.etcd.security_path}/server.crt" do
    content node.etcd.security_certificate
    mode '0644'
  end
  file "#{node.etcd.security_path}/server.key" do
    content node.etcd.security_key
    mode '0644'
  end

  file "#{node.etcd.security_path}/ca.crt" do
    content node.etcd.security_ca_certificate
    mode '0644'
  end

  security_flags = {
      'ETCD_CERT_FILE' => "#{node.etcd.security_path}/server.crt",
      'ETCD_KEY_FILE' => "#{node.etcd.security_path}/server.key",
      'ETCD_TRUSTED_CA_FILE' => "#{node.etcd.security_path}/ca.crt",
      'ETCD_CLIENT_CERT_AUTH' => 'true'
  }.merge(JSON.parse(node.etcd.security_flags))

elsif node.etcd.security_enabled == 'false'
  protocol = 'http'
  security_flags = {
  }.merge(JSON.parse(node.etcd.security_flags))
end

# Update default configuration with parameters passed by user in oneops design
member_flags = {
    'ETCD_NAME' => local_server_name,
    'ETCD_DATA_DIR' => "/var/lib/etcd/#{local_server_name}.etcd",
    'ETCD_SNAPSHOT_COUNT' => '10000',
    'ETCD_HEARTBEAT_INTERVAL' => '100',
    'ETCD_ELECTION_TIMEOUT' => '1000',
    'ETCD_LISTEN_PEER_URLS' => "http://#{local_server_ip}:2380",
    'ETCD_LISTEN_CLIENT_URLS' => "#{protocol}://#{local_server_ip}:2379,#{protocol}://127.0.0.1:2379",
    'ETCD_MAX_SNAPSHOTS' => '5',
    'ETCD_MAX_WALS' => '5',
    'ETCD_CORS' => 'none'
}.merge(JSON.parse(node.etcd.member_flags))

etcd_initial_cluster_token = primary_cloud ? 'etcd-cluster-1' : 'etcd-cluster-2'

cluster_flags = {
    'ETCD_INITIAL_ADVERTISE_PEER_URLS' => "http://#{local_server_ip}:2380",
    'ETCD_INITIAL_CLUSTER' => "#{etcd_cluster.join(",")}",
    'ETCD_INITIAL_CLUSTER_STATE' => 'new',
    'ETCD_INITIAL_CLUSTER_TOKEN' => etcd_initial_cluster_token,
    'ETCD_ADVERTISE_CLIENT_URLS' => "#{protocol}://#{local_server_ip}:2379"
}.merge(JSON.parse(node.etcd.cluster_flags))

proxy_flags = {
    'ETCD_PROXY' => 'off',
    'ETCD_PROXY_FAILURE_WAIT' => '5000',
    'ETCD_PROXY_REFRESH_INTERVAL' => '30000',
    'ETCD_PROXY_DIAL_TIMEOUT' => '1000',
    'ETCD_PROXY_WRITE_TIMEOUT' => '5000',
    'ETCD_PROXY_READ_TIMEOUT' => '0'
}.merge(JSON.parse(node.etcd.proxy_flags))

logging_flags = {
    'ETCD_DEBUG' => 'false',
    'ETCD_LOG_PACKAGE_LEVELS' => 'none'
}.merge(JSON.parse(node.etcd.logging_flags))

unsafe_flags = {
    'ETCD_FORCE_NEW_CLUSTER' => 'false'
}.merge(JSON.parse(node.etcd.unsafe_flags))

experimental_flags = {
    'ETCD_EXPERIMENTAL_V3DEMO' => 'false'
}.merge(JSON.parse(node.etcd.experimental_flags))

miscellaneous_flags = {
    'ETCD_VERSION' => 'false'
}.merge(JSON.parse(node.etcd.miscellaneous_flags))

profiling_flags = {
    'ETCD_ENABLE_PPROF' => 'false'
}.merge(JSON.parse(node.etcd.profiling_flags))

# setting all configuation flags to the node
node.set['etcd']['member'] = member_flags
node.set['etcd']['cluster'] = cluster_flags
node.set['etcd']['proxy'] = proxy_flags
node.set['etcd']['security'] = security_flags
node.set['etcd']['logging'] = logging_flags
node.set['etcd']['unsafe'] = unsafe_flags
node.set['etcd']['experimental'] = experimental_flags
node.set['etcd']['miscellaneous'] = miscellaneous_flags
node.set['etcd']['profiling'] = profiling_flags

# writing etcd config file
template node.etcd.conf_file do
  source 'etcd.conf.erb'
  mode 0644
  variables({
                :member_flags => node.etcd.member,
                :cluster_flags => node.etcd.cluster,
                :proxy_flags => node.etcd.proxy,
                :security_flags => node.etcd.security,
                :logging_flags => node.etcd.logging,
                :unsafe_flags => node.etcd.unsafe,
                :experimental_flags => node.etcd.experimental,
                :miscellaneous_flags => node.etcd.miscellaneous,
                :profiling_flags => node.etcd.profiling
            })
end
