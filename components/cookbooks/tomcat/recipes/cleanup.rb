#
# Cookbook Name:: tomcat
# Recipe:: cleanup
#

major_and_minor_version = node.workorder.rfcCi.ciBaseAttributes.has_key?("version")? node.workorder.rfcCi.ciBaseAttributes.version : node.tomcat.version
major_version = major_and_minor_version.gsub(/\..*/,"")
install_type = node.workorder.rfcCi.ciBaseAttributes.has_key?("install_type") ? node.workorder.rfcCi.ciBaseAttributes.install_type : node.tomcat.install_type
tomcat_install_dir = node.workorder.rfcCi.ciBaseAttributes.has_key?("tomcat_install_dir") ? node.workorder.rfcCi.ciBaseAttributes.tomcat_install_dir : node.tomcat.tomcat_install_dir
webapp_install_dir = node.workorder.rfcCi.ciBaseAttributes.has_key?("webapp_install_dir") ? node.workorder.rfcCi.ciBaseAttributes.webapp_install_dir : node.tomcat.webapp_install_dir
logfiles_path = node.workorder.rfcCi.ciBaseAttributes.has_key?("logfiles_path") ? node.workorder.rfcCi.ciBaseAttributes.logfiles_path : node.tomcat.logfiles_path
access_log_dir = node.workorder.rfcCi.ciBaseAttributes.has_key?("access_log_dir") ? node.workorder.rfcCi.ciBaseAttributes.access_log_dir : node.tomcat.access_log_dir

case install_type

when "binary"
Chef::Log.info("performing tomcat cleanup by removing directories #{tomcat_install_dir}, #{webapp_install_dir}, #{logfiles_path}, #{access_log_dir}")
["#{tomcat_install_dir}", "#{webapp_install_dir}", "#{logfiles_path}", "#{access_log_dir}"].each do |dir|
	directory dir do
		recursive true
		action :delete
	end
end

when "repository"
Chef::Log.info("performing tomcat cleanup by removing package tomcat#{major_version}")
package "tomcat#{major_version}" do
	action :remove
end

end