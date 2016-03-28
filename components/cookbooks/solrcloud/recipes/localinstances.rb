#
# Cookbook Name:: solrcloud
# Recipe:: localinstances.rb
#
# 
#
#

ci = node.workorder.rfcCi.ciAttributes;
solr_version = ci[:solr_version]
solr_package_type = ci[:solr_package_type]
solr_file_woext = "#{solr_package_type}-"+"#{solr_version}"

zk_select = ci[:zk_select]
if "#{zk_select}".include? "Internal"
  num_local_instances = ci[:num_local_instances]
  http_port_nos = ci[:http_port_nos]
  ssl_port_nos = ci[:ssl_port_nos]
  server_port_nos = ci[:server_port_nos]
  ajp_port_nos = ci[:ajp_port_nos]

  if !"#{num_local_instances}".empty? && !"#{http_port_nos}".empty? && !"#{ssl_port_nos}".empty? && !"#{server_port_nos}".empty? && !"#{ajp_port_nos}".empty?
    size = "#{num_local_instances}"
    http_port_nos = http_port_nos.split(",")
    ssl_port_nos = ssl_port_nos.split(",")
    server_port_nos = server_port_nos.split(",")
    ajp_port_nos = ajp_port_nos.split(",")
    
    if (http_port_nos.length == Integer(size)) && (ssl_port_nos.length == Integer(size)) && (server_port_nos.length == Integer(size)) && (ajp_port_nos.length == Integer(size))
      zk_host_fqdns = "#{node['ipaddress']}:2181"
    
      tomcatpath = `readlink -f #{node['tomcat']['dir']}`
      tomcatpath = tomcatpath.gsub("\n",'')

      for i in 1..Integer(size)
        bash "create_tomcat_instances" do
          user "#{node['solr']['user']}"
          code <<-EOH
            cp -r /app/apache-tomcat-7.0.67/ #{tomcatpath}.#{i}/
          EOH
        end

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

        bash "update_setenv" do
          code <<-EOH
            rm #{tomcatpath}.#{i}/bin/setenv.sh
            touch #{tomcatpath}.#{i}/bin/setenv.sh
            grep -q -F 'CATALINA_OPTS=' #{tomcatpath}.#{i}/bin/setenv.sh || echo 'CATALINA_OPTS=\"-Djava.awt.headless=true\"' >> #{tomcatpath}.#{i}/bin/setenv.sh
            grep -q -F 'zkHost' #{tomcatpath}.#{i}/bin/setenv.sh || echo 'export CATALINA_OPTS=\"\$CATALINA_OPTS -DzkHost=#{zk_host_fqdns}\"' >> #{tomcatpath}.#{i}/bin/setenv.sh
            grep -q -F 'CATALINA_HOME' #{tomcatpath}.#{i}/bin/setenv.sh || echo 'CATALINA_HOME=#{tomcatpath}.#{i}' >> #{tomcatpath}.#{i}/bin/setenv.sh
            grep -q -F 'CATALINA_PID' #{tomcatpath}.#{i}/bin/setenv.sh || echo 'CATALINA_PID=#{tomcatpath}.#{i}/tomcat.pid' >> #{tomcatpath}.#{i}/bin/setenv.sh
            grep -q -F 'CATALINA_BASE' #{tomcatpath}.#{i}/bin/setenv.sh || echo 'CATALINA_BASE=#{tomcatpath}.#{i}' >> #{tomcatpath}.#{i}/bin/setenv.sh
          EOH
        end
      end

      ruby_block 'add_connector_tag' do
        block do
          for i in 1..Integer(size)
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
      Chef::Log.error("no of port numbers mismatch the no of instances")
    end
  else
    Chef::Log.error("num_local_instances parameters are not specified . Failed to continue install solrcloud on multiple instances")
  end
end





