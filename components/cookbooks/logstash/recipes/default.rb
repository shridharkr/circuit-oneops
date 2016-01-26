require 'json'

nodes = node.workorder.payLoad.RequiresComputes 
availability_mode = node.workorder.box.ciAttributes.availability

ci = node.workorder.rfcCi
# node.logstash[:version] = ci.version

input_version = node.logstash['version']
if !input_version.nil? && ! input_version.empty?
	node.set[:logstash][:version] = input_version
end

tmp = Chef::Config[:file_cache_path]
# [node.logstash[:host], node.logstash[:repository], node.logstash[:filename]].join('/')
source_list = [node.logstash[:download_url],"https://download.elasticsearch.org/logstash/logstash/logstash-"+node.logstash[:version]+".tar.gz"]
dest_file = "#{tmp}/"+node.logstash[:filename]
Chef::Log.info("Download URL::" + node.logstash[:download_url])
remote_file dest_file do
  source node.logstash[:download_url]
end

untar_dir = "/opt/logstash-"+node.logstash[:version]

execute "untar_logstash" do
  command "tar -zxf #{dest_file}; rm -fr /opt/logstash ; ln -sf #{untar_dir} /opt/logstash"
  cwd "/opt"
end

logstash_inputs = ""
inputs = JSON.parse(ci.ciAttributes.inputs)
logstash_inputs = "#{inputs.join("\n")}"

logstash_filters = ""
if ci.ciAttributes.has_key?("filters") &&
      !node.workorder.rfcCi.ciAttributes.filters.empty?
  filters = JSON.parse(ci.ciAttributes.filters)
  logstash_filters = "#{filters.join("\n")}"
end

logstash_outputs = ""
outputs = JSON.parse(ci.ciAttributes.outputs)
logstash_outputs = "#{outputs.join("\n")}"

config = "input { \n #{logstash_inputs}   } \n " +
          "filter { \n #{logstash_filters} } \n" +
          "output { \n #{logstash_outputs } }" 
          
`mkdir -p /etc/logstash/`          
File.open("/etc/logstash/logstash.conf", 'w') {|f| f.write(config) } 

template "/etc/init.d/logstash" do
  source "initd.erb"
  owner "root"
  group "root"
  mode 0700
end

cookbook_file '/opt/nagios/libexec/check_logstash' do
  source 'check_logstash.rb'
  owner 'root'
  group 'root'
  mode 0755
end
     
# ensure the service is running
service 'logstash' do
  action :start
end          
