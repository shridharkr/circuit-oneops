##############################################################################
# Global
###############################################################################
Chef::Log.debug("version: #{node['tomcat']['global']['version']}")
    Chef::Log.debug("tomcat_user: %#{node['tomcat']['global']['tomcat_user']}%")
Chef::Log.debug("tomcat_group: #{node['tomcat']['global']['tomcat_group']}")
Chef::Log.debug("environment_settings:")
JSON.parse(node['tomcat']['global']['environment_settings']).each{ |k, v|
  Chef::Log.debug("    #{k}=#{v}")
}
Chef::Log.debug("override_context_enabled: #{node['tomcat']['context']['override_context_enabled']}")
Chef::Log.debug("context_tomcat: #{node['tomcat']['context']['context_tomcat']}")
##############################################################################
# Server
###############################################################################
Chef::Log.debug("override_server_enabled: #{node['tomcat']['server']['override_server_enabled']}")
Chef::Log.debug("server_tomcat: #{node['tomcat']['server']['server_tomcat']}")
Chef::Log.debug("autodeploy_enabled: #{node['tomcat']['server']['autodeploy_enabled']}")
Chef::Log.debug("http_nio_connector_enabled: #{node['tomcat']['server']['http_nio_connector_enabled']}")
Chef::Log.debug("https_nio_connector_enabled: #{node['tomcat']['server']['https_nio_connector_enabled']}")
Chef::Log.debug("advanced_nio_connector_config:")
JSON.parse(node['tomcat']['server']['advanced_nio_connector_config']).each{ |k, v|
  Chef::Log.debug("    #{k}=#{v}")
}
Chef::Log.debug("port: #{node['tomcat']['server']['port']}")
Chef::Log.debug("ssl_port: #{node['tomcat']['server']['ssl_port']}")
Chef::Log.debug("advanced_security_options: #{node['tomcat']['server']['advanced_security_options']}")
Chef::Log.debug("tlsv11_protocol_enabled: #{node['tomcat']['server']['tlsv11_protocol_enabled']}")
Chef::Log.debug("tlsv12_protocol_enabled: #{node['tomcat']['server']['tlsv12_protocol_enabled']}")
Chef::Log.debug("enable_method_get: #{node['tomcat']['server']['enable_method_get']}")
Chef::Log.debug("enable_method_put: #{node['tomcat']['server']['enable_method_put']}")
Chef::Log.debug("enable_method_post: #{node['tomcat']['server']['enable_method_post']}")
Chef::Log.debug("enable_method_delete: #{node['tomcat']['server']['enable_method_delete']}")
Chef::Log.debug("enable_method_connect: #{node['tomcat']['server']['enable_method_connect']}")
Chef::Log.debug("enable_method_options: #{node['tomcat']['server']['enable_method_options']}")
Chef::Log.debug("enable_method_head: #{node['tomcat']['server']['enable_method_head']}")
Chef::Log.debug("enable_method_trace: #{node['tomcat']['server']['enable_method_trace']}")
Chef::Log.debug("max_threads: #{node['tomcat']['server']['max_threads']}")
Chef::Log.debug("min_spare_threads: #{node['tomcat']['server']['min_spare_threads']}")

###############################################################################
# Java
###############################################################################
Chef::Log.debug("java_options: #{node['tomcat']['java']['java_options']}")
Chef::Log.debug("system_properties:")
JSON.parse(node['tomcat']['java']['system_properties']).each{ |k, v|
  Chef::Log.debug("#{k}=#{v}")
}
Chef::Log.debug("startup_params:")
JSON.parse(node['tomcat']['java']['startup_params']).each{ |k, v|
  Chef::Log.debug("#{k}=#{v}")
}
Chef::Log.debug("mem_max: #{node['tomcat']['java']['mem_max']}")
Chef::Log.debug("mem_start: #{node['tomcat']['java']['mem_start']}")

###############################################################################
# Logs
###############################################################################
Chef::Log.debug("logfiles_path: #{node['tomcat']['logs']['logfiles_path']}")
Chef::Log.debug("access_log_pattern: #{node['tomcat']['logs']['access_log_pattern']}")

###############################################################################
# Startup_shutdown
###############################################################################
Chef::Log.debug("stop_time: #{node['tomcat']['startup_shutdown']['stop_time']}")
Chef::Log.debug("pre_shutdown_command: #{node['tomcat']['startup_shutdown']['pre_shutdown_command']}")
Chef::Log.debug("time_to_wait_before_shutdown: #{node['tomcat']['startup_shutdown']['time_to_wait_before_shutdown']}")
Chef::Log.debug("post_shutdown_command: #{node['tomcat']['startup_shutdown']['post_shutdown_command']}")
Chef::Log.debug("pre_startup_command: #{node['tomcat']['startup_shutdown']['pre_startup_command']}")
Chef::Log.debug("post_startup_command: #{node['tomcat']['startup_shutdown']['post_startup_command']}")
Chef::Log.debug("polling_frequency_post_startup_check: #{node['tomcat']['startup_shutdown']['polling_frequency_post_startup_check']}")
Chef::Log.debug("max_number_of_retries_for_post_startup_check: #{node['tomcat']['startup_shutdown']['max_number_of_retries_for_post_startup_check']}")
