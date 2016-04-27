# Cookbook Name:: etcd
# Attributes:: delete
#
# Author : OneOps
# Apache License, Version 2.0

require 'net/http'
require 'uri'

# Removing etcd member
member_id=node.workorder.rfcCi['ciAttributes']['member_id']
uri = URI.parse("http://localhost:2379/v2/members/#{member_id}")
http = Net::HTTP.new(uri.host, uri.port)
req = Net::HTTP::Delete.new(uri.path)
res = http.request(req)

if res.code != '204'
  msg = "Failure deleting etcd member #{member_id}. response code: #{res.code}, response body #{res.body}, response message #{res.message}"
  Chef::Log.error(msg)
  puts "***FAULT:FATAL= #{msg}"
  e = Exception.new('no backtrace')
  e.set_backtrace('')
  raise e
else
  msg = "Success deleting etcd member #{member_id}. response code: #{res.code}, response body #{res.body}, response message #{res.message}"
  Chef::Log.info(msg)
end

# stop etcd service.
service 'etcd' do
  action :stop
end

# remove etcd files
execute "rm -rf /tmp/etcd* #{node.etcd.working_location} #{node.etcd.conf_location} /usr/bin/etcd* #{node.etcd.systemd_file} #{node.etcd.extract_path} #{node.etcd.security_path}"
