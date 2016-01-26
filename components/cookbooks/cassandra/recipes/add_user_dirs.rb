user "cassandra" do
  gid "nobody"
  shell "/bin/false"
end

directory "/opt/cassandra/lib.so" do
  owner "cassandra"
  group "root"
  mode "0755"
  action :create
end

directory "/var/lib/cassandra" do
  owner "cassandra"
  group "root"
  mode "0755"
  action :create
end

directory "/var/run/cassandra" do
  owner "cassandra"
  group "root"
  mode "0755"
  action :create
end

directory "/var/log/cassandra" do
  owner "cassandra"
  group "root"
  mode "0755"
  action :create
end
