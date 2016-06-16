#
# Cookbook Name:: tomcat
# Recipe:: cleanup
#

major_and_minor_version = get_attribute_value("version")
build_version = get_attribute_value("build_version")
major_version = major_and_minor_version.gsub(/\..*/,"")
full_version = "#{major_and_minor_version}.#{build_version}"

tomcat_install_dir = get_attribute_value("tomcat_install_dir")
webapp_install_dir = get_attribute_value("webapp_install_dir")
logfiles_path = get_attribute_value("logfiles_path")
access_log_dir = get_attribute_value("access_log_dir")

install_type = get_attribute_value("install_type")
dest_file = "#{tomcat_install_dir}/apache-tomcat-#{full_version}.tar.gz"
service_script = "/etc/init.d/tomcat"+ major_version

Chef::Log.info("performing tomcat cleanup..")

case install_type
	when "binary"
		Chef::Log.warn("removing symlink #{tomcat_install_dir}/tomcat#{major_version}")
		link "#{tomcat_install_dir}/tomcat#{major_version}" do
			action :delete
			only_if "test -L #{tomcat_install_dir}/tomcat#{major_version}"
		end

		Chef::Log.warn("removing directories #{tomcat_install_dir}/apache-tomcat-#{full_version}, #{webapp_install_dir}, #{logfiles_path} and #{access_log_dir}")
		["#{tomcat_install_dir}/apache-tomcat-#{full_version}", "#{webapp_install_dir}", "#{logfiles_path}", "#{access_log_dir}"].each do |dir|
			directory dir do
				recursive true
				action :delete
			end
		end

		Chef::Log.warn("removing files #{dest_file} and #{service_script}")
		["#{dest_file}", "#{service_script}"].each  do |f|
			file f do
				action :delete
			end
		end
	when "repository"
		Chef::Log.warn("removing package tomcat#{major_version}")
		package "tomcat#{major_version}" do
			action :remove
		end
end
