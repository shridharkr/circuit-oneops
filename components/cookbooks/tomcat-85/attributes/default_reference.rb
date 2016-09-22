# rubocop:disable LineLength
###############################################################################
#
#
# Tomcat defaults from metadata.rb
#
#
###############################################################################

###############################################################################
# Global Variables from metadata.rb
###############################################################################
set['tomcat']['global']['tomcat_install_dir'] = node.workorder.rfcCi.ciAttributes.tomcat_install_dir
set['tomcat']['global']['version'] = node.workorder.rfcCi.ciAttributes.version

set['tomcat']['global']['tomcat_user'] = node.workorder.rfcCi.ciAttributes.tomcat_user
if node['tomcat']['global']['tomcat_user'].empty?
  Chef::Log.error("tomcat_user was empty: setting to tomcat")
  set['tomcat']['global']['tomcat_user'] = 'tomcat'
end

set['tomcat']['global']['tomcat_group'] = node.workorder.rfcCi.ciAttributes.tomcat_group
if node['tomcat']['global']['tomcat_group'].empty?
  Chef::Log.error("tomcat_group was empty: setting to tomcat")
  set['tomcat']['global']['tomcat_group'] = 'tomcat'
end

set['tomcat']['global']['environment_settings'] = node.workorder.rfcCi.ciAttributes.environment_settings

###############################################################################
# Context Variables from metadata.rb
###############################################################################
set['tomcat']['context']['override_context_enabled'] = node.workorder.rfcCi.ciAttributes.override_context_enabled
set['tomcat']['context']['context_tomcat'] = node.workorder.rfcCi.ciAttributes.context_tomcat

###############################################################################
# Server Variables from metadata.rb
###############################################################################
set['tomcat']['server']['override_server_enabled'] = node.workorder.rfcCi.ciAttributes.override_server_enabled
set['tomcat']['server']['server_tomcat'] = node.workorder.rfcCi.ciAttributes.server_tomcat
set['tomcat']['server']['autodeploy_enabled'] = node.workorder.rfcCi.ciAttributes.autodeploy_enabled
set['tomcat']['server']['http_nio_connector_enabled'] = node.workorder.rfcCi.ciAttributes.http_nio_connector_enabled
set['tomcat']['server']['https_nio_connector_enabled'] = node.workorder.rfcCi.ciAttributes.https_nio_connector_enabled
set['tomcat']['server']['advanced_nio_connector_config'] = node.workorder.rfcCi.ciAttributes.advanced_nio_connector_config

set['tomcat']['server']['port'] = node.workorder.rfcCi.ciAttributes.port
set['tomcat']['server']['ssl_port'] = node.workorder.rfcCi.ciAttributes.ssl_port
set['tomcat']['server']['advanced_security_options'] = node.workorder.rfcCi.ciAttributes.advanced_security_options
set['tomcat']['server']['tlsv11_protocol_enabled'] = node.workorder.rfcCi.ciAttributes.tlsv11_protocol_enabled
set['tomcat']['server']['tlsv12_protocol_enabled'] = node.workorder.rfcCi.ciAttributes.tlsv12_protocol_enabled
set['tomcat']['server']['enable_method_get'] = node.workorder.rfcCi.ciAttributes.enable_method_get
set['tomcat']['server']['enable_method_put'] = node.workorder.rfcCi.ciAttributes.enable_method_put
set['tomcat']['server']['enable_method_post'] = node.workorder.rfcCi.ciAttributes.enable_method_post
set['tomcat']['server']['enable_method_delete'] = node.workorder.rfcCi.ciAttributes.enable_method_delete
set['tomcat']['server']['enable_method_connect'] = node.workorder.rfcCi.ciAttributes.enable_method_connect
set['tomcat']['server']['enable_method_options'] = node.workorder.rfcCi.ciAttributes.enable_method_options
set['tomcat']['server']['enable_method_head'] = node.workorder.rfcCi.ciAttributes.enable_method_head
set['tomcat']['server']['enable_method_trace'] = node.workorder.rfcCi.ciAttributes.enable_method_trace
set['tomcat']['server']['max_threads'] = node.workorder.rfcCi.ciAttributes.max_threads
set['tomcat']['server']['min_spare_threads'] = node.workorder.rfcCi.ciAttributes.min_spare_threads

###############################################################################
# Java Variables from metadata.rb
###############################################################################
set['tomcat']['java']['java_options'] = node.workorder.rfcCi.ciAttributes.java_options
set['tomcat']['java']['system_properties'] = node.workorder.rfcCi.ciAttributes.system_properties
set['tomcat']['java']['startup_params'] = node.workorder.rfcCi.ciAttributes.startup_params
set['tomcat']['java']['mem_max'] = node.workorder.rfcCi.ciAttributes.mem_max
set['tomcat']['java']['mem_start'] = node.workorder.rfcCi.ciAttributes.mem_start

###############################################################################
# Logs Variables from metadata.rb
###############################################################################
set['tomcat']['logs']['logfiles_path'] = node.workorder.rfcCi.ciAttributes.logfiles_path
set['tomcat']['logs']['access_log_pattern'] = node.workorder.rfcCi.ciAttributes.access_log_pattern

###############################################################################
# Startup_shutdown Variables from metadata.rb
###############################################################################
set['tomcat']['startup_shutdown']['stop_time'] = node.workorder.rfcCi.ciAttributes.stop_time
set['tomcat']['startup_shutdown']['pre_shutdown_command'] = node.workorder.rfcCi.ciAttributes.pre_shutdown_command
set['tomcat']['startup_shutdown']['time_to_wait_before_shutdown'] = node.workorder.rfcCi.ciAttributes.time_to_wait_before_shutdown
set['tomcat']['startup_shutdown']['post_shutdown_command'] = node.workorder.rfcCi.ciAttributes.post_shutdown_command
set['tomcat']['startup_shutdown']['pre_startup_command'] = node.workorder.rfcCi.ciAttributes.pre_startup_command
set['tomcat']['startup_shutdown']['post_startup_command'] = node.workorder.rfcCi.ciAttributes.post_startup_command
set['tomcat']['startup_shutdown']['polling_frequency_post_startup_check'] = node.workorder.rfcCi.ciAttributes.polling_frequency_post_startup_check
set['tomcat']['startup_shutdown']['max_number_of_retries_for_post_startup_check'] = node.workorder.rfcCi.ciAttributes.max_number_of_retries_for_post_startup_check
