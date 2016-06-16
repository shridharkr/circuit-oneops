#
# Cookbook Name:: tomcat
# Recipe:: cleanup
#

# retrieving versions
major_and_minor_version = node.workorder.rfcCi.ciBaseAttributes.has_key?("version")? node.workorder.rfcCi.ciBaseAttributes.version : node.tomcat.version
build_version = node.workorder.rfcCi.ciBaseAttributes.has_key?("build_version")? node.workorder.rfcCi.ciBaseAttributes.build_version : node.tomcat.build_version
major_version = major_and_minor_version.gsub(/\..*/,"")
full_version = "#{major_and_minor_version}.#{build_version}"

# retrieving directories
tomcat_install_dir = node.workorder.rfcCi.ciBaseAttributes.has_key?("tomcat_install_dir") ? node.workorder.rfcCi.ciBaseAttributes.tomcat_install_dir : node.tomcat.tomcat_install_dir
webapp_install_dir = node.workorder.rfcCi.ciBaseAttributes.has_key?("webapp_install_dir") ? node.workorder.rfcCi.ciBaseAttributes.webapp_install_dir : node.tomcat.webapp_install_dir
logfiles_path = node.workorder.rfcCi.ciBaseAttributes.has_key?("logfiles_path") ? node.workorder.rfcCi.ciBaseAttributes.logfiles_path : node.tomcat.logfiles_path
access_log_dir = node.workorder.rfcCi.ciBaseAttributes.has_key?("access_log_dir") ? node.workorder.rfcCi.ciBaseAttributes.access_log_dir : node.tomcat.access_log_dir

# retrieving install type
install_type = node.workorder.rfcCi.ciBaseAttributes.has_key?("install_type") ? node.workorder.rfcCi.ciBaseAttributes.install_type : node.tomcat.install_type
dest_file = "#{tomcat_install_dir}/apache-tomcat-#{full_version}.tar.gz"
service_script = "/etc/init.d/tomcat"+ major_version

case install_type
	when "binary"
		Chef::Log.info("removing symlink #{tomcat_install_dir}/tomcat#{major_version}")
		link "#{tomcat_install_dir}/tomcat#{major_version}" do
			action :delete
			only_if "test -L #{tomcat_install_dir}/tomcat#{major_version}"
		end

		Chef::Log.info("removing directories #{tomcat_install_dir}/apache-tomcat-#{full_version}, #{webapp_install_dir}, #{logfiles_path} and #{access_log_dir}")
		["#{tomcat_install_dir}/apache-tomcat-#{full_version}", "#{webapp_install_dir}", "#{logfiles_path}", "#{access_log_dir}"].each do |dir|
			directory dir do
				recursive true
				action :delete
			end
		end

		Chef::Log.info("removing #{dest_file} and #{service_script}")
		["#{dest_file}", "#{service_script}"].each  do |f|
			file f do
				action :delete
			end
		end
	when "repository"
		Chef::Log.info("performing tomcat cleanup by removing package tomcat#{major_version}")
		package "tomcat#{major_version}" do
			action :remove
		end
end
