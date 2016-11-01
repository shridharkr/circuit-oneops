# included via windowos::add

home_dir = "C:/opscode/logstash-forwarder"
bin_dir = "#{home_dir}/bin"
cert_path = "#{home_dir}/logstash.crt"
nagios_log_path = "C:/Cygwin64/var/log/nagios3"
cygwinsrv_install = "C:/Cygwin64/bin/cygrunsrv.exe -I logstash-forwarder -p #{bin_dir}/logstash-forwarder.exe -a '-config=#{home_dir}/logstash-forwarder.conf -spool-size 20'"

dest="#{node["workorder"][:cloud][:ciName]}.collector.#{node[:mgmt_domain].strip}:5000"
ipaddress = node[:ipaddress]
perf_collector_cert = node[:perf_collector_cert]

ServiceExists = ::Win32::Service.exists?("logstash-forwarder")

#stop logstash-forwarder service
service 'logstash-forwarder' do
  action [:stop]
  only_if {ServiceExists}
end

#set up a working folder for logstash-forwarder
directory bin_dir do
  recursive true
end

#create a certificate file
file cert_path do
  content perf_collector_cert
end

#bring the executable 
cookbook_file "logstash-forwarder.exe" do
  path "#{bin_dir}/logstash-forwarder.exe"
end

#generate config file, from a template
template "#{home_dir}/logstash-forwarder.conf" do
  source "logstash-forwarder.conf.erb"
  variables({
    :destination => dest,
    :cert_path=> cert_path,
    :ip => ipaddress,
	:nagios_log_path => nagios_log_path
  })
end

#install service - powershell
powershell_script 'Install service' do
  code cygwinsrv_install
  guard_interpreter :powershell_script
  not_if {ServiceExists}
end

#start logstash-forwarder service
service 'logstash-forwarder' do
	action [:enable, :start]
end