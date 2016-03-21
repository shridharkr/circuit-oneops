#
# Cookbook Name:: solrcloud
# Recipe:: solrcloud.rb
#
# The recipie extracts the solr.war and copies the WEB-INF/lib/ jars to solr-war-lib folder.
#
#

extend Java::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, Java::Util)

ci = node.workorder.rfcCi.ciAttributes;
solr_version = ci[:solr_version]
solr_format = ci[:solr_format]
solr_package_type = ci[:solr_package_type]
solr_file_name = "#{solr_package_type}-"+"#{solr_version}."+"#{solr_format}";
solr_file_woext = "#{solr_package_type}-"+"#{solr_version}";
solr_filepath = "#{node['user']['dir']}/#{solr_file_name}";
config_name = ci[:config_name]
zk_host_fqdns = '';

num_local_instances = ci[:num_local_instances]
zkp_version = ci[:zkp_version]
zkp_format = ci[:zkp_format]
zkp_file_name = "zookeeper-#{zkp_version}"
zkp_file_path = "/app/#{zkp_file_name}.#{zkp_format}"
zkp_base_url = "#{node['zookeeper']['url']}"
zkp_url = "#{zkp_base_url}/#{zkp_version}/#{zkp_file_name}.#{zkp_format}";


if node.workorder.rfcCi.ciAttributes.deploy_all_dcs == 'true'
  #zk_host_fqdns = zookeeper;
  zk_host_fqdns = ci[:zk_host_fqdns]
  if "#{zk_host_fqdns}".empty?
    zk_host_fqdns = ci[:zk_host_fqdns]
  end
else
  zk_host_fqdns = ci[:zk_host_fqdns]
end

solr_extract_path = "#{node['user']['dir']}/tmp/tgz";
solr_war_lib = "#{node['user']['dir']}/solr-war-lib";
solr_config = "#{node['user']['dir']}/solr-config";
solr_cores = "#{node['user']['dir']}/solr-cores";
solr_default_dir = "#{solr_config}/default";


Chef::Log.info('Create Directory "solr-war-lib" ')
directory "#{solr_war_lib}" do
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0755'
  action :create
end

Chef::Log.info('Create Directory "solr-config" ')
directory "#{solr_config}" do
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0755'
  action :create
end

Chef::Log.info('Create Directory "solr-config/default" ')
directory "#{solr_default_dir}" do
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0755'
  action :create
end

Chef::Log.info('Create Directory "solr-cores" ')
directory "#{solr_cores}" do
  not_if { ::File.directory?("#{node['user']['dir']}/solr-cores") }
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0755'
  action :create
end

Chef::Log.info('Create Directory "tmp" ')
directory "#{node['user']['dir']}/tmp" do
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0755'
  action :create
end

Chef::Log.info('Create Directory "solr_extract_path" ')
directory "#{solr_extract_path}" do
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0755'
  action :create
end

Chef::Log.info('UnPack solr.war and extract the WEB-INF/lib to solr-war-lib/ folder')
bash 'unpack_solr_war' do
  code <<-EOH
    cd #{node['user']['dir']}
    rm -rf solr-*.txt
    echo #{solr_version} > solr-#{solr_version}.txt
    mv #{solr_file_name} #{node['user']['dir']}/tmp/tgz/
    cd #{node['user']['dir']}/tmp/tgz
    tar -xvf #{solr_file_name}
    cp #{solr_file_woext}/dist/#{solr_file_woext}.war ../
    cd ..
    jar xvf #{solr_file_woext}.war
    rm -rf #{node['user']['dir']}/solr-war-lib/*
    rm -rf #{node['user']['dir']}/solr.war
    cp #{node['user']['dir']}/tmp/WEB-INF/lib/* #{solr_war_lib}
    cp #{node['user']['dir']}/*.jar #{solr_war_lib}
    cp #{solr_file_woext}.war solr.war
    cp solr.war #{node['user']['dir']}
    rm -rf #{node['user']['dir']}/solr-config/default/*
    cp -irf #{node['user']['dir']}/tmp/tgz/#{solr_file_woext}/example/solr/collection1/conf/* #{node['user']['dir']}/solr-config/default/
  EOH
  not_if { ::File.exists?("#{node['user']['dir']}/solr-#{solr_version}.txt") }
end

Chef::Log.info("Deleting #{node['user']['dir']}/tmp directory")
directory "#{node['user']['dir']}/tmp" do
  only_if { ::File.directory?("#{node['user']['dir']}/tmp") }
  recursive true
  action :delete
end

if node.workorder.rfcCi.ciAttributes.deploy_embed_zkp == 'true'
  if !"#{num_local_instances}".empty?
    zk_host_fqdns = "#{node['ipaddress']}:2181"
    size = "#{num_local_instances}"
    tomcatpath = `readlink -f /app/tomcat#{node['tomcatversion']}`
    tomcatpath = tomcatpath.gsub("\n",'')

    ## Download zookeeper
    Chef::Log.info("Download zookeeper from gec-nexus: #{zkp_url}")
    remote_file zkp_file_path do
      source "#{zkp_url}"
      owner "#{node['solr']['user']}"
      group "#{node['solr']['user']}"
      mode '0644'
      action :create_if_missing
    end

    ## Install zookeeper
    bash "install_zookeeper" do
      user "#{node['solr']['user']}"
      Chef::Log.info("Install zookeeper locally.")
      code <<-EOH
        cd #{node['user']['dir']}
        tar -xvf #{zkp_file_path}
        chown app:app #{zkp_file_name}/
        /app/#{zkp_file_name}/bin/zkServer.sh stop       
        mv #{node['user']['dir']}/#{zkp_file_name}/conf/zoo_sample.cfg #{node['user']['dir']}/zookeeper-3.4.6/conf/zoo.cfg
        /app/#{zkp_file_name}/bin/zkServer.sh start
      EOH
    end

    for i in 1..Integer(size)-1
      bash "create_tomcat_instances" do
        user "#{node['solr']['user']}"
        code <<-EOH
          cp -r /app/apache-tomcat-7.0.67/ #{tomcatpath}.#{i}/
          rm #{tomcatpath}.#{i}/bin/setenv.sh
          touch #{tomcatpath}.#{i}/bin/setenv.sh
          grep -q -F 'CATALINA_OPTS=' #{tomcatpath}.#{i}/bin/setenv.sh || echo 'CATALINA_OPTS=\"-Djava.awt.headless=true\"' >> #{tomcatpath}.#{i}/bin/setenv.sh
          grep -q -F 'zkHost' #{tomcatpath}.#{i}/bin/setenv.sh || echo 'export CATALINA_OPTS=\"\$CATALINA_OPTS -DzkHost=#{zk_host_fqdns}\"' >> #{tomcatpath}.#{i}/bin/setenv.sh
        EOH
      end
    end

    bash "add_zookeeper_conn_string" do
      code <<-EOH
        grep -q -F 'zkHost' #{node['tomcat']['dir']}/bin/setenv.sh || echo 'export CATALINA_OPTS=\"\$CATALINA_OPTS -DzkHost=#{zk_host_fqdns}\"' >> #{node['tomcat']['dir']}/bin/setenv.sh
      EOH
    end
  else
    Chef::Log.error("num_local_instances parameters are not specified . Failed to continue installing solrcloud")
  end
else
  bash "update_zookeeper_string" do
    code <<-EOH
      grep -q -F 'zkHost' #{node['tomcat']['dir']}/bin/setenv.sh || echo 'export CATALINA_OPTS=\"\$CATALINA_OPTS -DzkHost=#{zk_host_fqdns}\"' >> #{node['tomcat']['dir']}/bin/setenv.sh
    EOH
  end
end

downloadconfig("#{zk_host_fqdns}","#{config_name}")
uploaddefaultconfig("#{zk_host_fqdns}","#{config_name}")

Chef::Log.info('Create/Update the solr.xml in /solr-cores')
cookbook_file "#{node['user']['dir']}/solr-cores/solr.xml" do
  source "solr.xml"
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0755'
  action :create_if_missing
end

execute 'notify-tomcat-restart' do
  command "service tomcat#{node['tomcatversion']} restart"
  user "root"
  action :run
  only_if { ::File.exists?("/etc/init.d/tomcat#{node['tomcatversion']}") }
end


