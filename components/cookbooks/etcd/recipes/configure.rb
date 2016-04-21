# Cookbook Name:: etcd
# Attributes:: configure
#
# Author : OneOps
# Apache License, Version 2.0

# Get all the required computes
computes = node.workorder.payLoad.RequiresComputes

# Get the local compute
local_server_ip = node.workorder.payLoad.ManagedVia[0]['ciAttributes']['private_ip']
local_server_name = node.workorder.payLoad.ManagedVia[0]['ciName']

# Get etcd members
etcd_cluster = Array.new
computes.each do |c, index|
  etcd_cluster.push("#{c.ciName}=http://#{c.ciAttributes.private_ip}:2380")
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

cluster_flags = {
    'ETCD_INITIAL_ADVERTISE_PEER_URLS' => "http://#{local_server_ip}:2380",
    'ETCD_INITIAL_CLUSTER' => "#{etcd_cluster.join(",")}",
    'ETCD_INITIAL_CLUSTER_STATE' => 'new',
    'ETCD_INITIAL_CLUSTER_TOKEN' => 'etcd-cluster-1',
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
