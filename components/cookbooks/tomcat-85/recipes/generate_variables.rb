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
node.set['tomcat']['global']['version'] = node.workorder.rfcCi.ciAttributes.version
node.set['tomcat']['global']['tomcat_user'] = node.workorder.rfcCi.ciAttributes.tomcat_user
  if node['tomcat']['global']['tomcat_user'].empty?
    Chef::Log.error("tomcat_user was empty: setting to tomcat")
    node.set['tomcat']['global']['tomcat_user'] = 'tomcat'
  end
node.set['tomcat']['global']['tomcat_group'] = node.workorder.rfcCi.ciAttributes.tomcat_group
  if node['tomcat']['global']['tomcat_group'].empty?
    Chef::Log.error("tomcat_group was empty: setting to tomcat")
    node.set['tomcat']['global']['tomcat_group'] = 'tomcat'
  end
node.set['tomcat']['global']['environment_settings'] = node.workorder.rfcCi.ciAttributes.environment_settings

##################################################################################################
# HANDLED - Attributes for context.xml Configuration
##################################################################################################
node.set['tomcat']['context']['override_context_enabled'] = node.workorder.rfcCi.ciAttributes.override_context_enabled
node.set['tomcat']['context']['context_tomcat'] = node.workorder.rfcCi.ciAttributes.context_tomcat

##################################################################################################
# HANDLED - Attributes for server.xml Configuration
##################################################################################################
node.set['tomcat']['server']['override_server_enabled'] = node.workorder.rfcCi.ciAttributes.override_server_enabled
node.set['tomcat']['server']['server_tomcat'] = node.workorder.rfcCi.ciAttributes.server_tomcat
node.set['tomcat']['server']['http_nio_connector_enabled'] = node.workorder.rfcCi.ciAttributes.http_nio_connector_enabled
node.set['tomcat']['server']['port'] = node.workorder.rfcCi.ciAttributes.port

node.set['tomcat']['server']['https_nio_connector_enabled'] = node.workorder.rfcCi.ciAttributes.https_nio_connector_enabled
node.set['tomcat']['server']['ssl_port'] = node.workorder.rfcCi.ciAttributes.ssl_port
node.set['tomcat']['server']['max_threads'] = node.workorder.rfcCi.ciAttributes.max_threads
node.set['tomcat']['server']['advanced_security_options'] = node.workorder.rfcCi.ciAttributes.advanced_security_options
node.set['tomcat']['server']['tlsv11_protocol_enabled'] = node.workorder.rfcCi.ciAttributes.tlsv11_protocol_enabled
node.set['tomcat']['server']['tlsv12_protocol_enabled'] = node.workorder.rfcCi.ciAttributes.tlsv12_protocol_enabled
node.set['tomcat']['server']['advanced_nio_connector_config'] = node.workorder.rfcCi.ciAttributes.advanced_nio_connector_config
node.set['tomcat']['server']['autodeploy_enabled'] = node.workorder.rfcCi.ciAttributes.autodeploy_enabled
node.set['tomcat']['server']['http_methods'] = node.workorder.rfcCi.ciAttributes.http_methods
node.set['tomcat']['server']['enable_method_get'] = node.workorder.rfcCi.ciAttributes.enable_method_get
node.set['tomcat']['server']['enable_method_put'] = node.workorder.rfcCi.ciAttributes.enable_method_put
node.set['tomcat']['server']['enable_method_post'] = node.workorder.rfcCi.ciAttributes.enable_method_post
node.set['tomcat']['server']['enable_method_delete'] = node.workorder.rfcCi.ciAttributes.enable_method_delete
node.set['tomcat']['server']['enable_method_connect'] = node.workorder.rfcCi.ciAttributes.enable_method_connect
node.set['tomcat']['server']['enable_method_options'] = node.workorder.rfcCi.ciAttributes.enable_method_options
node.set['tomcat']['server']['enable_method_head'] = node.workorder.rfcCi.ciAttributes.enable_method_head
node.set['tomcat']['server']['enable_method_trace'] = node.workorder.rfcCi.ciAttributes.enable_method_trace

##################################################################################################
# Attributes set in the setenv.sh script
##################################################################################################
node.set['tomcat']['java']['java_options'] = node.workorder.rfcCi.ciAttributes.java_options
node.set['tomcat']['java']['system_properties'] = node.workorder.rfcCi.ciAttributes.system_properties
node.set['tomcat']['java']['startup_params'] = node.workorder.rfcCi.ciAttributes.startup_params
node.set['tomcat']['java']['mem_max'] = node.workorder.rfcCi.ciAttributes.mem_max
node.set['tomcat']['java']['mem_start'] = node.workorder.rfcCi.ciAttributes.mem_start

##################################################################################################
# Attributes to control log settings
##################################################################################################
node.set['tomcat']['logs']['logfiles_path'] = node.workorder.rfcCi.ciAttributes.logfiles_path
  if !node['tomcat']['logs']['logfiles_path'].match('^/')
    node.set['tomcat']['logs']['logfiles_path'] = "/#{node['tomcat']['logs']['logfiles_path']}"
  end
node.set['tomcat']['logs']['access_log_pattern'] = node.workorder.rfcCi.ciAttributes.access_log_pattern

##################################################################################################
# Attributes for Tomcat instance startup and shutdown processes
##################################################################################################
node.set['tomcat']['startup_shutdown']['stop_time'] = node.workorder.rfcCi.ciAttributes.stop_time
node.set['tomcat']['startup_shutdown']['pre_shutdown_command'] = node.workorder.rfcCi.ciAttributes.pre_shutdown_command
node.set['tomcat']['startup_shutdown']['time_to_wait_before_shutdown'] = node.workorder.rfcCi.ciAttributes.time_to_wait_before_shutdown
node.set['tomcat']['startup_shutdown']['post_shutdown_command'] = node.workorder.rfcCi.ciAttributes.post_shutdown_command
node.set['tomcat']['startup_shutdown']['pre_startup_command'] = node.workorder.rfcCi.ciAttributes.pre_startup_command
node.set['tomcat']['startup_shutdown']['post_startup_command'] = node.workorder.rfcCi.ciAttributes.post_startup_command
node.set['tomcat']['startup_shutdown']['polling_frequency_post_startup_check'] = node.workorder.rfcCi.ciAttributes.polling_frequency_post_startup_check
node.set['tomcat']['startup_shutdown']['max_number_of_retries_for_post_startup_check'] = node.workorder.rfcCi.ciAttributes.max_number_of_retries_for_post_startup_check

##################################################################################################
# Tomcat variables not in metadata.rb
##################################################################################################
node.set['tomcat']['tomcat_install_dir'] = '/opt'
node.set['tomcat']['config_dir'] = '/opt/tomcat'
node.set['tomcat']['instance_dir'] = "#{node['tomcat']['config_dir']}/apache-tomcat-#{node['tomcat']['global']['version']}"
node.set['tomcat']['tarball'] = "tomcat/tomcat-8/v#{node['tomcat']['global']['version']}/bin/apache-tomcat-#{node['tomcat']['global']['version']}.tar.gz"
node.set['tomcat']['download_destination'] = "#{node['tomcat']['config_dir']}/apache-tomcat-#{node['tomcat']['global']['version']}.tar.gz"
node.set['tomcat']['webapp_install_dir'] = "#{node['tomcat']['instance_dir']}/webapps"
node.set['tomcat']['tmp_dir'] = "#{node['tomcat']['config_dir']}/temp"
node.set['tomcat']['work_dir'] = "#{node['tomcat']['config_dir']}/work"
node.set['tomcat']['catalina_dir'] = "#{node['tomcat']['config_dir']}/Catalina"
node.set['tomcat']['context_dir'] = "#{node['tomcat']['catalina_dir']}/localhost"
node.set['tomcat']['keystore_path'] = "#{node['tomcat']['instance_dir']}/ssl/keystore.jks"
node.set['tomcat']['keystore_pass'] = "changeit"
node.set['tomcat']['shutdown_port'] = 8005
node.set['tomcat']['use_security_manager'] = false
node.set['tomcat']['ssl_configured_ciphers'] = 'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_256_CBC_SHA256,TLS_DHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_CAMELLIA_256_CBC_SHA,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_CAMELLIA_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_CBC_SHA256,TLS_DHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_CAMELLIA_128_CBC_SHA,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_CAMELLIA_128_CBC_SHA,TLS_DHE_RSA_WITH_SEED_CBC_SHA,TLS_RSA_WITH_SEED_CBC_SHA'
node.set['java']['java_home'] = '/usr'
node.set['tomcat']['home'] = '/usr/share/tomcat'
node.set['tomcat']['base'] = '/usr/share/tomcat'
