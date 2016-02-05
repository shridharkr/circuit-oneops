
package "jna"


dist = node.workorder.rfcCi.ciAttributes.version

version_parts = dist.split(".")

if version_parts.size < 3

  case dist
  when "2.2"
     v = "2.2.4"
  when "2.1"
   v = "2.1.12"
  when "2.0"
    v = "2.0.17"
  when "1.2"
    v = "1.2.18"
  else
    Chef::Log.error("unsupported #{dist}")
    exit 1
  end

else
  
  # full version with patch level x.x.x
  v = dist
  
  # to share config templates by minor version
  version_parts.pop  
  dist = version_parts.join(".")  
end

sub_dir = "/cassandra/#{v}/"
tgz_file = "apache-cassandra-#{v}-bin.tar.gz"

tmp = Chef::Config[:file_cache_path]

# try component mirrors first, if empty try cloud mirrors, if empty use cookbook mirror attribute
source_list = JSON.parse(node.cassandra.mirrors).map!{ |mirror| "#{mirror}/#{sub_dir}#{tgz_file}"}
if source_list.empty?
  cloud_name = node[:workorder][:cloud][:ciName]
  mirrors = []
  if node[:workorder][:services].has_key? "mirror"
    mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
  end
  source_list = mirrors['apache'].split(",").map { |mirror| "#{mirror}#{sub_dir}#{tgz_file}" }
end
source_list = [ node['cassandra']['src_mirror'] ] if source_list.empty?
source_list = [ "http://archive.apache.org/dist" ] if source_list.empty?
dest_file = "#{tmp}/#{tgz_file}"
  
shared_download_http source_list.join(",") do
  path dest_file
  action :create
  if node[:cassandra][:checksum] && !node[:cassandra][:checksum].empty?
    checksum node[:cassandra][:checksum]
  end
end

untar_dir = "/opt/apache-cassandra-#{v}"

execute "untar_cassandra" do
  command "tar -zxf #{dest_file}; rm -fr /opt/cassandra ; ln -sf #{untar_dir} /opt/cassandra"
  cwd "/opt"
end

execute "ln -fs /usr/share/java/jna.jar /opt/cassandra/lib" do 
  only_if { ::File.exist?("/usr/share/java/jna.jar") }
end

include_recipe "cassandra::add_user_dirs"


template "/opt/cassandra/conf/cassandra.yaml" do
  source "cassandra-#{dist}.yaml.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/opt/cassandra/conf/cassandra-env.sh" do
  source "cassandra-env.sh.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/etc/init.d/cassandra" do
  source "initd.erb"
  owner "root"
  group "root"
  mode 0700
end

if dist == "2.1"
  template "/opt/cassandra/conf/logback.xml" do
    source "logback.xml.erb"
    owner "root"
    group "root"
    mode 0644
  end  
end

