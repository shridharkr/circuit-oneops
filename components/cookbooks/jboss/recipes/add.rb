#
# Cookbook Name:: jboss
# Recipe:: add
#
# JBoss add recipe
#

jboss_version = node.workorder.rfcCi.ciAttributes.version
short_jboss_version = jboss_version.gsub(/\.\d+$/,'')

#http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.tar.gz
#http://download.jboss.org/jbossas/7.0/jboss-as-7.0.2.Final/jboss-as-7.0.2.Final.tar.gz

dl_url = "http://download.jboss.org/jbossas/#{short_jboss_version}/jboss-as-#{jboss_version}.Final/jboss-as-#{jboss_version}.Final.tar.gz"
base_name = "jboss-as-#{jboss_version}.Final"

jboss_home = node['jboss']['jboss_home']
jboss_user = node['jboss']['jboss_user']

user jboss_user do
  system true
  shell '/bin/false'
  action :create
  only_if { jboss_user == "jboss" }
end
package 'wget'
# get files
bash "put_files" do
  code <<-EOH
  cd /tmp
  wget #{dl_url}
  cd /opt
  tar -zxf /tmp/#{base_name}.tar.gz
  ln -s /opt/#{base_name} #{jboss_home}
  rm -f /tmp/#{base_name}.tar.gz
  chown -R #{jboss_user}:#{jboss_user} /opt/#{base_name}
  EOH
  not_if "test -d #{jboss_home}"
end

template "#{jboss_home}/standalone/configuration/standalone.xml" do
  source 'standalone.xml.erb'
  owner jboss_user
end

# template init file
template "/etc/init.d/jboss" do
  if platform? ["centos", "redhat"] 
    source "init_el.erb"
  else
    source "init_deb.erb"
  end
  mode "0755"
  owner "root"
  group "root"
end

# start service
service "jboss" do
  action [ :enable, :start ]
end
