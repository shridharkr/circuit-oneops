#
# Cookbook Name:: couchbase
# Recipe:: status
#
#service "couchbase-server" do
#   status_command "sudo /etc/init.d/couchbase-server status"
#  supports :status => true
#  action :status
#  action :nothing
#end
msg = `sudo /etc/init.d/couchbase-server status`
msg = msg.strip!
if msg == 'couchbase-server is not running'
  Chef::Application.fatal!("#{msg}")
else
  Chef::Log.info("COUCHBASE STATUS: #{msg}")
end
