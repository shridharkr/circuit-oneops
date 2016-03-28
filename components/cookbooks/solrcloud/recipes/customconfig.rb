#
# Cookbook Name:: solrcloud
# Recipe:: customconfig.rb
#
# The recipie downloads the custom config uploads to Zookeeper.
#
#

extend Java::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, Java::Util)


solr_config = "/app/solr-config";

ci = node.workorder.rfcCi.ciAttributes;
config_name = ci[:custom_config_name]
config_url = ci[:custom_config_url]
config_dir = '';
config_jar = '';
delete_config = "sudo find . ! -name \"*.jar\" -exec rm -r {} \\;";



zk_select = ci[:zk_select]
if "#{zk_select}".include? "Internal"
  zk_host_fqdns = "#{node['ipaddress']}:2181"
else
  zk_host_fqdns = ci[:zk_host_fqdns]
end


Chef::Log.info('Create Directory "solr-war-lib"')
directory "#{solr_config}/prod" do
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0777'
  action :create
end

if !"#{config_url}".empty?
  config_url = config_url.delete(' ');
end
if !"#{config_name}".empty?
  config_name = config_name.delete(' ');
end

if "#{config_url}".empty?
  Chef::Log.info(" prod config url is empty ")
else
  Chef::Log.info(" config_url --- "+"#{config_url}")
  config_dir = "#{config_url}".split("/").last.split(".jar").first;
  config_jar = "#{config_dir}"+".jar";
  Chef::Log.info(" config_jar --- "+"#{config_jar}")

  if "#{config_jar}".empty?
    Chef::Log.info(" prod config jar is empty ")
  else
    Chef::Log.info(" config jar :: "+"#{config_jar}")
    remote_file solr_config+"/"+config_jar do
      source "#{config_url}"
      owner "#{node['solr']['user']}"
      group "#{node['solr']['user']}"
      mode '0777'
    end
  end

  Chef::Log.info('Unpack prod config files')
  bash 'unpack_prodconfig_jar' do
    code <<-EOH
      cd #{solr_config}
      rm -rf *.txt
      echo #{config_dir} > #{config_dir}.txt
      chown #{node['solr']['user']}:#{node['solr']['user']} #{config_dir}.txt
      cp #{config_jar} prod/
      rm -rf #{config_jar}
      cd prod
      #{delete_config}
      jar -xvf #{config_jar}
      cp -R iroconf1/* .
      sudo rm -rf #{config_jar}
      sudo rm -R iroconf1/
    EOH
    not_if { ::File.exists?("#{solr_config}/#{config_dir}.txt") }
  end

  downloadconfig("#{zkpfqdn}","#{config_name}")
  uploadprodconfig("#{zkpfqdn}","#{config_name}")
end

