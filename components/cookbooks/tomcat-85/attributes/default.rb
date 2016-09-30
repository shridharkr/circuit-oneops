# rubocop:disable LineLength
##################################################################################################
#
#
# Tomcat defaults from metadata.rb
#
#
##################################################################################################

##################################################################################################
# HANDLED - Global attributes for Tomcat 8.5
##################################################################################################
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

##################################################################################################
# HANDLED - Attributes for context.xml Configuration
##################################################################################################
set['tomcat']['context']['override_context_enabled'] = node.workorder.rfcCi.ciAttributes.override_context_enabled
set['tomcat']['context']['context_tomcat'] = node.workorder.rfcCi.ciAttributes.context_tomcat

##################################################################################################
# HANDLED - Attributes for server.xml Configuration
##################################################################################################
set['tomcat']['server']['override_server_enabled'] = node.workorder.rfcCi.ciAttributes.override_server_enabled
set['tomcat']['server']['server_tomcat'] = node.workorder.rfcCi.ciAttributes.server_tomcat
set['tomcat']['server']['http_nio_connector_enabled'] = node.workorder.rfcCi.ciAttributes.http_nio_connector_enabled
set['tomcat']['server']['port'] = node.workorder.rfcCi.ciAttributes.port

set['tomcat']['server']['https_nio_connector_enabled'] = node.workorder.rfcCi.ciAttributes.https_nio_connector_enabled
set['tomcat']['server']['ssl_port'] = node.workorder.rfcCi.ciAttributes.ssl_port
set['tomcat']['server']['max_threads'] = node.workorder.rfcCi.ciAttributes.max_threads
set['tomcat']['server']['advanced_security_options'] = node.workorder.rfcCi.ciAttributes.advanced_security_options
set['tomcat']['server']['tlsv11_protocol_enabled'] = node.workorder.rfcCi.ciAttributes.tlsv11_protocol_enabled
set['tomcat']['server']['tlsv12_protocol_enabled'] = node.workorder.rfcCi.ciAttributes.tlsv12_protocol_enabled
set['tomcat']['server']['advanced_nio_connector_config'] = node.workorder.rfcCi.ciAttributes.advanced_nio_connector_config
set['tomcat']['server']['autodeploy_enabled'] = node.workorder.rfcCi.ciAttributes.autodeploy_enabled
set['tomcat']['server']['http_methods'] = node.workorder.rfcCi.ciAttributes.http_methods
set['tomcat']['server']['enable_method_get'] = node.workorder.rfcCi.ciAttributes.enable_method_get
set['tomcat']['server']['enable_method_put'] = node.workorder.rfcCi.ciAttributes.enable_method_put
set['tomcat']['server']['enable_method_post'] = node.workorder.rfcCi.ciAttributes.enable_method_post
set['tomcat']['server']['enable_method_delete'] = node.workorder.rfcCi.ciAttributes.enable_method_delete
set['tomcat']['server']['enable_method_connect'] = node.workorder.rfcCi.ciAttributes.enable_method_connect
set['tomcat']['server']['enable_method_options'] = node.workorder.rfcCi.ciAttributes.enable_method_options
set['tomcat']['server']['enable_method_head'] = node.workorder.rfcCi.ciAttributes.enable_method_head
set['tomcat']['server']['enable_method_trace'] = node.workorder.rfcCi.ciAttributes.enable_method_trace

##################################################################################################
# Attributes set in the setenv.sh script
##################################################################################################
set['tomcat']['java']['java_options'] = node.workorder.rfcCi.ciAttributes.java_options
set['tomcat']['java']['system_properties'] = node.workorder.rfcCi.ciAttributes.system_properties
set['tomcat']['java']['startup_params'] = node.workorder.rfcCi.ciAttributes.startup_params
set['tomcat']['java']['mem_max'] = node.workorder.rfcCi.ciAttributes.mem_max
set['tomcat']['java']['mem_start'] = node.workorder.rfcCi.ciAttributes.mem_start

##################################################################################################
# Attributes to control log settings
##################################################################################################
set['tomcat']['logs']['logfiles_path'] = node.workorder.rfcCi.ciAttributes.logfiles_path
  if !node['tomcat']['logs']['logfiles_path'].match('^/')
    set['tomcat']['logs']['logfiles_path'] = "/#{node['tomcat']['logs']['logfiles_path']}"
  end
set['tomcat']['logs']['access_log_pattern'] = node.workorder.rfcCi.ciAttributes.access_log_pattern

##################################################################################################
# Attributes for Tomcat instance startup and shutdown processes
##################################################################################################
set['tomcat']['startup_shutdown']['stop_time'] = node.workorder.rfcCi.ciAttributes.stop_time
set['tomcat']['startup_shutdown']['pre_shutdown_command'] = node.workorder.rfcCi.ciAttributes.pre_shutdown_command
set['tomcat']['startup_shutdown']['time_to_wait_before_shutdown'] = node.workorder.rfcCi.ciAttributes.time_to_wait_before_shutdown
set['tomcat']['startup_shutdown']['post_shutdown_command'] = node.workorder.rfcCi.ciAttributes.post_shutdown_command
set['tomcat']['startup_shutdown']['pre_startup_command'] = node.workorder.rfcCi.ciAttributes.pre_startup_command
set['tomcat']['startup_shutdown']['post_startup_command'] = node.workorder.rfcCi.ciAttributes.post_startup_command
set['tomcat']['startup_shutdown']['polling_frequency_post_startup_check'] = node.workorder.rfcCi.ciAttributes.polling_frequency_post_startup_check
set['tomcat']['startup_shutdown']['max_number_of_retries_for_post_startup_check'] = node.workorder.rfcCi.ciAttributes.max_number_of_retries_for_post_startup_check

##################################################################################################
# Tomcat variables not in metadata.rb
##################################################################################################
default['tomcat']['tomcat_install_dir'] = '/opt'
default['tomcat']['java']['jre_home'] = '/usr/lib/jvm/jre'
default['tomcat']['config_dir'] = '/opt/tomcat'
default['tomcat']['instance_dir'] = "#{node['tomcat']['config_dir']}/apache-tomcat-#{node['tomcat']['global']['version']}"
default['tomcat']['tarball'] = "tomcat/tomcat-8/v#{node['tomcat']['global']['version']}/bin/apache-tomcat-#{node['tomcat']['global']['version']}.tar.gz"
default['tomcat']['download_destination'] = "#{node['tomcat']['config_dir']}/apache-tomcat-#{node['tomcat']['global']['version']}.tar.gz"
default['tomcat']['webapp_install_dir'] = "#{tomcat['instance_dir']}/webapps"
default['tomcat']['tmp_dir'] = "#{node['tomcat']['config_dir']}/temp"
default['tomcat']['work_dir'] = "#{node['tomcat']['config_dir']}/work"
default['tomcat']['catalina_dir'] = "#{node['tomcat']['config_dir']}/Catalina"
default['tomcat']['context_dir'] = "#{node['tomcat']['catalina_dir']}/localhost"
default['tomcat']['keystore_path'] = "#{node['tomcat']['instance_dir']}/ssl/keystore.jks"
default['tomcat']['keystore_pass'] = "changeit"
default['tomcat']['shutdown_port'] = 8005
default['tomcat']['use_security_manager'] = false
default['tomcat']['ssl_configured_ciphers'] = 'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_256_CBC_SHA256,TLS_DHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_CAMELLIA_256_CBC_SHA,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_CAMELLIA_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_CBC_SHA256,TLS_DHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_CAMELLIA_128_CBC_SHA,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_CAMELLIA_128_CBC_SHA,TLS_DHE_RSA_WITH_SEED_CBC_SHA,TLS_RSA_WITH_SEED_CBC_SHA'
###############################################################################
# End of default.rb
###############################################################################
