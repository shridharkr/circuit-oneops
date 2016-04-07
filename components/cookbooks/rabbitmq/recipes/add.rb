nodes = node.workorder.payLoad.RequiresComputes
dist = node.workorder.rfcCi.ciAttributes.version
dpath = node.workorder.rfcCi.ciAttributes.datapath

rabbitmq = node['rabbitmq']

location = rabbitmq['src_url'] + "v" + rabbitmq['version'] + "/" + "rabbitmq-server-" + rabbitmq['version'] + "-1" + ".noarch.rpm"
file = "rabbitmq-server-" + rabbitmq['version'] + "-1" + ".noarch.rpm"

case node[:platform]
when "debian", "ubuntu"
  rabbitmq_repository "rabbitmq" do
    uri "http://www.rabbitmq.com/debian/"
    distribution "testing"
    components ["main"]
    key "http://www.rabbitmq.com/rabbitmq-signing-key-public.asc"
    action :add
  end
  package "rabbitmq-server" do
    action :install
    options "--force-yes"
  end
when "redhat", "centos", "fedora"
  package "erlang"
  package "wget"
end

bash "Install Rabbitmq" do
  code <<-EOH
  cd /tmp
  wget #{location}
  rpm -ivh /tmp/#{file}
  chkconfig rabbitmq-server on
  EOH
end

execute "Stop rabbitmq-server" do
  command "service rabbitmq-server stop"
end

directory "/etc/rabbitmq/" do
  owner "root"
  group "root"
  mode 0755
  action :create
end

template "/etc/rabbitmq/rabbitmq-env.conf" do
  source "rabbitmq-env.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/var/lib/rabbitmq/.erlang.cookie" do
  source "doterlang.cookie.erb"
  owner "rabbitmq"
  group "rabbitmq"
  mode 0400
end

execute "Remove old rabbitmq data directory" do
  command "rm -rf /var/lib/rabbitmq/mnesia"
end

directory "#{dpath}" do
  owner "rabbitmq"
  group "rabbitmq"
  mode 0755
  action :create
  recursive true
end

execute "Start rabbitmq-server" do
  command "service rabbitmq-server start"
end

execute "Enable Rabbitmq Management" do
  not_if "/usr/lib/rabbitmq/bin/rabbitmq-plugins  list | grep '\[E\].*rabbitmq_management'"
  command "/usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management"
  user 0
  action :run
end

rabbitmq_user "guest" do
  password "guest123"
  action :add
end

rabbitmq_user "nova" do
  password "sekret"
  action :add
end

rabbitmq_user "guest" do
  permissions "\".*\" \".*\" \".*\""
  action :set_permissions
end

rabbitmq_user "nova" do
  permissions "\".*\" \".*\" \".*\""
  action :set_permissions
end

execute "Enable Rabbitmq Management for user nova" do
  command "/usr/sbin/rabbitmqctl set_user_tags nova administrator"
  action :run
end

execute "Enable Rabbitmq Management for user guest" do
  command "/usr/sbin/rabbitmqctl set_user_tags guest administrator"
  action :run
end

execute "Restart rabbitmq-server" do
  command "service rabbitmq-server restart"
end
