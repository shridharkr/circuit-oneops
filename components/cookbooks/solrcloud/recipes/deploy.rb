#
# Cookbook Name:: solrcloud
# Recipe:: deploy.rb
#
# The recipie deploys the solr.war in tomcat web server.
#
#

extend Java::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, Java::Util)

ci = node.workorder.rfcCi.ciAttributes;
solr_version = ci[:solr_version]
http_port_nos = ci[:http_port_nos]
ssl_port_nos = ci[:ssl_port_nos]
server_port_nos = ci[:server_port_nos]
ajp_port_nos = ci[:ajp_port_nos]
num_local_instances = ci[:num_local_instances]
zk_host_fqdns = '';
config_name = ci[:config_name]

if node.workorder.rfcCi.ciAttributes.deploy_all_dcs == 'true'
  Chef::Log.info(node.workorder)
  #zk_host_fqdns = zookeeper;
  zk_host_fqdns = ci[:zk_host_fqdns]
  if "#{zk_host_fqdns}".empty?
    zk_host_fqdns = ci[:zk_host_fqdns]
  end
else
  zk_host_fqdns = ci[:zk_host_fqdns]
end


Chef::Log.info('Tomcat log4j.properties file')
template "#{node['tomcat']['dir']}/lib/log4j.properties" do
  source 'log4j.properties.erb'
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0755'
  action :create_if_missing
end

Chef::Log.info('deploy solr.war in tomcat')
bash 'deploy_solr_war' do  
  code <<-EOH
    cd #{node['user']['dir']}
    sudo rm -rf deploy-*.txt
    echo #{solr_version} > deploy-#{solr_version}.txt  
    rm -rf #{node['tomcat']['dir']}/webapps/solr
    rm -rf #{node['tomcat']['dir']}/webapps/solr.war
    sudo cp solr.war #{node['tomcat']['dir']}/webapps/
    sudo cp #{node['user']['dir']}/*.jar #{node['tomcat']['dir']}/lib/
  EOH
  notifies :run, 'execute[notify-tomcat-restart]', :immediately
  not_if { ::File.exists?("#{node['user']['dir']}/deploy-#{solr_version}.txt") }
end

Chef::Log.info('Create the solr.xml in Catalina/localhost')
template "#{node['tomcat']['dir']}/conf/Catalina/localhost/solr.xml" do
  source 'solr.xml.erb'
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0777'
  mode '0777'
  notifies :run, 'execute[notify-tomcat-restart]', :immediately
  not_if { ::File.exists?("#{node['tomcat']['dir']}/conf/Catalina/localhost/solr.xml") }
end

execute 'notify-tomcat-restart' do
  command "service tomcat#{node['tomcatversion']} restart"
  user "root"
  action :run
  only_if { ::File.exists?("/etc/init.d/tomcat#{node['tomcatversion']}") }
end

if node.workorder.rfcCi.ciAttributes.deploy_embed_zkp == 'true'
  if !"#{num_local_instances}".empty? && !"#{http_port_nos}".empty? && !"#{ssl_port_nos}".empty? && !"#{server_port_nos}".empty? && !"#{ajp_port_nos}".empty?

    tomcatpath = `readlink -f /app/tomcat#{node['tomcatversion']}`
    tomcatpath = tomcatpath.gsub("\n",'')
    size = "#{num_local_instances}"

    for i in 1..Integer(size)-1
      Chef::Log.info('Tomcat log4j.properties file')
      template "#{tomcatpath}.#{i}/lib/log4j.properties" do
        source 'log4j.properties.erb'
        owner "#{node['solr']['user']}"
        group "#{node['solr']['user']}"
        mode '0755'
        action :create_if_missing
      end

      Chef::Log.info('deploy solr.war in tomcat')
      bash 'deploy_solr_war' do  
        code <<-EOH
          cd #{node['user']['dir']}
          sudo cp solr.war #{tomcatpath}.#{i}/webapps/
          sudo cp #{node['user']['dir']}/*.jar #{tomcatpath}.#{i}/lib/
        EOH
      end

      Chef::Log.info('Create the solr.xml in Catalina/localhost')
      template "#{tomcatpath}.#{i}/conf/Catalina/localhost/solr.xml" do
        source 'solr.xml.erb'
        owner "#{node['solr']['user']}"
        group "#{node['solr']['user']}"
        mode '0777'
        mode '0777'
        not_if { ::File.exists?("#{tomcatpath}.#{i}/conf/Catalina/localhost/solr.xml") }
      end

      bash "update_catalina_path" do
        code <<-EOH
          grep -q -F 'CATALINA_HOME' #{tomcatpath}.#{i}/bin/setenv.sh || echo 'CATALINA_HOME=#{tomcatpath}.#{i}' >> #{tomcatpath}.#{i}/bin/setenv.sh
          grep -q -F 'CATALINA_PID' #{tomcatpath}.#{i}/bin/setenv.sh || echo 'CATALINA_PID=#{tomcatpath}.#{i}/tomcat.pid' >> #{tomcatpath}.#{i}/bin/setenv.sh
          grep -q -F 'CATALINA_BASE' #{tomcatpath}.#{i}/bin/setenv.sh || echo 'CATALINA_BASE=#{tomcatpath}.#{i}' >> #{tomcatpath}.#{i}/bin/setenv.sh
        EOH
      end
    end

    downloadconfig("#{zk_host_fqdns}","#{config_name}")
    uploaddefaultconfig("#{zk_host_fqdns}","#{config_name}")

    http_port_nos = http_port_nos.split(",")
    ssl_port_nos = ssl_port_nos.split(",")
    server_port_nos = server_port_nos.split(",")
    ajp_port_nos = ajp_port_nos.split(",")

    ## update tomcat ports and start tomcat instances
    ruby_block 'add_connector_tag' do
      block do
        for i in 1..Integer(size)-1
          Chef::Log.info("i value = "+"#{i}")
          fe = Chef::Util::FileEdit.new("#{tomcatpath}.#{i}/conf/server.xml")
          fe.search_file_replace(/8080/, http_port_nos[i-1])
          fe.search_file_replace(/8443/, ssl_port_nos[i-1])
          fe.search_file_replace(/8005/, server_port_nos[i-1])
          fe.search_file_replace(/8009/, ajp_port_nos[i-1])
          fe.write_file
          `#{tomcatpath}.#{i}/bin/startup.sh&`
        end
      end
    end
  else
    Chef::Log.error(" num_local_instances,list_port_nos parameters are not specified . Failed to continue installing solrcloud")
  end
end







