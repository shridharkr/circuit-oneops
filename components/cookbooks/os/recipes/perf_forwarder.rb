# included via os::add

#to stop and disable old flume agent
service "perf-agent" do
   action [ :stop, :disable ]
   only_if "test -L /etc/init.d/perf-agent"
end

link "/etc/init.d/perf-agent" do
   action :delete
   only_if "test -L /etc/init.d/perf-agent"
end

#delete the initd service because we are going to create a systemd service
file '/etc/init.d/perf-agent' do
   action :delete
   only_if {File.exists?("/etc/init.d/perf-agent")}
end

service 'perf-agent' do
  action :stop
end

destination="#{node.workorder.cloud.ciName}.collector.#{node.mgmt_domain.strip}:5000"
Chef::Log.info("Installing logstash-forwarder...")
#Create sub directories
`mkdir -p /etc/logstash/cert/`
`mkdir -p /etc/logstash/conf.d/`
`mkdir -p /etc/logstash-forwarder/`
`mkdir -p /opt/logstash-forwarder/bin`
 
# Create/Update the certificate file 
cert_path = "/etc/logstash/cert/perf-agent-lsf.crt"
cert_content = node.perf_collector_cert
File.open(cert_path, "w") do |f|
  f.write(cert_content)
end

config_dir = "/etc/logstash/conf.d/"

template "/etc/logstash-forwarder/perf-agent-lsf.conf" do
  source "logstash-forwarder.conf.erb"
  mode 0600
  variables({
    :destination => destination,
    :cert_path=> "/etc/logstash/cert/perf-agent-lsf.crt",
    :ip => node[:ipaddress]
  })
  owner "root"
  group "root"
end

cookbook_file "logstash-forwarder" do
  path "/opt/logstash-forwarder/bin/logstash-forwarder"
  source "logstash-forwarder"
  owner "root"
  group "root"
  mode 0700
end

# systemd
if File.directory?("/usr/lib/systemd/system")
  template "/usr/lib/systemd/system/perf-agent.service" do
    source "perf-agent-service.erb"
    variables({
      :log_dir => "/opt/oneops/log"
    })
    owner "root"
    group "root"
    mode 0700
  end
else
  # sysv init.d
  template "/etc/init.d/perf-agent" do
    source "lsf-initd.erb"
    variables({
      :log_dir => "/opt/oneops/log"
    })
    owner "root"
    group "root"
    mode 0700
  end
  
end

template "/etc/rsyslog.d/oneops-perf-agent.conf" do
  source "log-conf.erb"
  owner "root"
  group "root"
  mode 0700
end

execute "service rsyslog restart"

#ensure the service is running
service 'perf-agent' do
	action [ :enable, :restart ]
end

