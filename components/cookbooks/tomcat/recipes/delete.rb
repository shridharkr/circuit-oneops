tomcat_pkgs = value_for_platform(
  ["debian","ubuntu"] => {
    "default" => ["tomcat6","tomcat6-admin"]
  },
  ["centos","redhat","fedora"] => {
    "default" => ["tomcat6","tomcat6-admin-webapps"]
  },
  "default" => ["tomcat6"]
)


service "tomcat" do
  only_if { ::File.exists?('/etc/init.d/tomcat6') }
  service_name "tomcat6"
  action [:stop, :disable]
end

tomcat_pkgs.each do |pkg|
  package pkg do
    action :purge
  end
end


case node["platform"]
when "centos","redhat","fedora"
  file "/etc/sysconfig/tomcat6" do
    action :delete
  end
else  
  file "/etc/default/tomcat6" do
    action :delete
  end
end

directory "/etc/tomcat6" do
  recursive true
  action :delete
end