# rubocop:disable LineLength
###############################################################################
# Tomcat defaults from metadata.rb
###############################################################################
#default['tomcat']['version'] = '8.5.2'
set['tomcat']['config_dir'] = '/opt/tomcat'
default['tomcat']['tomcat_version_name'] = "8.5.2"
default['tomcat']['instance_dir'] = "#{node['tomcat']['config_dir']}/apache-tomcat-#{node['tomcat']['tomcat_version_name']}"
default['tomcat']['port'] = 8080
default['tomcat']['ssl_port'] = 8443
default['tomcat']['java_options'] = '-Djava.awt.headless=true -Djavax.net.ssl.trustStore="/opt/tomcat/ssl/trust.jks"'
default['tomcat']['webapp_install_dir'] = "#{tomcat['instance_dir']}/webapps"
default['tomcat']['stop_time'] = 45
default['tomcat']['max_threads'] = 50
default['tomcat']['min_spare_threads'] = 25
default['tomcat']['tomcat_user'] = 'tomcat'
default['tomcat']['tomcat_group'] = 'tomcat'
default['tomcat']['logfiles_path'] = "#{tomcat['config_dir']}/logs"
default['tomcat']['keystore_path'] = "#{tomcat['instance_dir']}/ssl/keystore.jks"
default['tomcat']['keystore_pass'] = "changeit"


#set['tomcat']['advanced_NIO_connector_config'] = node.workorder.rfcCi.ciAttributes['advanced_NIO_connector_config']
#Chef::Log.warn("default copy of advanced_NIO_connector_config = #{node['tomcat']['advanced_NIO_connector_config']}")

set['tomcat']['advanced_NIO_connector_config2'] = node.workorder.rfcCi.ciAttributes.tomcat.advanced_NIO_connector_config
Chef::Log.warn("default copy of advanced_NIO_connector_config2 = #{node['tomcat']['advanced_NIO_connector_config2']}")

set['tomcat']['advanced_NIO_connector_config3'] = node.workorder.rfcCi.ciBaseAttributes['advanced_NIO_connector_config']
Chef::Log.warn("default copy of advanced_NIO_connector_config3 = #{node['tomcat']['advanced_NIO_connector_config3']}")

set['tomcat']['advanced_NIO_connector_config4'] = node.workorder.rfcCi.ciBaseAttributes.advanced_NIO_connector_config
Chef::Log.warn("default copy of advanced_NIO_connector_config4 = #{node['tomcat']['advanced_NIO_connector_config4']}")

#set['tomcat']['advanced_NIO_connector_config'] = get_attribute_value('advanced_NIO_connector_config')
=begin
set['tomcat']['tomcat_install_dir'] = node.workorder.rfcCi.ciBaseAttributes.tomcat_install_dir
set['tomcat']['version']
set['tomcat']['tomcat_user']
set['tomcat']['tomcat_group']
set['tomcat']['webapp_install_dir']
set['tomcat']['environment_settings']
set['tomcat']['override_context_enabled']
set['tomcat']['context_tomcat']
set['tomcat']['override_server_enabled']
set['tomcat']['server_tomcat']
set['tomcat']['autodeploy_enabled']
set['tomcat']['http_NIO_connector_enabled']
set['tomcat']['https_NIO_connector_enabled']

set['tomcat']['port']
set['tomcat']['ssl_port']
set['tomcat']['advanced_security_options']
set['tomcat']['tlsv11_protocol_enabled']
set['tomcat']['tlsv12_protocol_enabled']
set['tomcat']['enable_method_get']
set['tomcat']['enable_method_put']
set['tomcat']['enable_method_post']
set['tomcat']['enable_method_delete']
set['tomcat']['enable_method_connect']
set['tomcat']['enable_method_options']
set['tomcat']['enable_method_head']
set['tomcat']['enable_method_trace']
set['tomcat']['max_threads']
set['tomcat']['min_spare_threads']
set['tomcat']['java_options']
set['tomcat']['system_properties']
set['tomcat']['startup_params']
set['tomcat']['mem_max']
set['tomcat']['mem_start']
set['tomcat']['logfiles_path']
set['tomcat']['access_log_pattern']
set['tomcat']['stop_time']
set['tomcat']['pre_shutdown_command']
set['tomcat']['time_to_wait_before_shutdown']
set['tomcat']['post_shutdown_command']
set['tomcat']['pre_startup_command']
set['tomcat']['post_startup_command']
set['tomcat']['polling_frequency_post_startup_check']
set['tomcat']['max_number_of_retries_for_post_startup_check']
=end
###############################################################################
# Tomcat defaults not in metadata.rb
###############################################################################
default['tomcat']['server_port'] = 8005
default['tomcat']['use_security_manager'] = false
# Tomcat will choose the appropriate ciphers from this list based on the TLS versions enabled.
default['tomcat']['ssl_configured_ciphers'] = 'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_256_CBC_SHA256,TLS_DHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_CAMELLIA_256_CBC_SHA,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_CAMELLIA_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_CBC_SHA256,TLS_DHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_CAMELLIA_128_CBC_SHA,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_CAMELLIA_128_CBC_SHA,TLS_DHE_RSA_WITH_SEED_CBC_SHA,TLS_RSA_WITH_SEED_CBC_SHA'

###############################################################################
# Private Variables for Tomcat
###############################################################################
set['java']['java_home'] = '/usr'
set['tomcat']['home'] = '/usr/share/tomcat'
set['tomcat']['base'] = '/usr/share/tomcat'
#set['tomcat']['config_dir'] = '/opt/tomcat'
set['tomcat']['tmp_dir'] = "#{tomcat['config_dir']}/temp"
set['tomcat']['work_dir'] = "#{tomcat['config_dir']}/work"
set['tomcat']['context_dir'] = "#{tomcat['config_dir']}/Catalina/localhost"
if !node['tomcat']['logfiles_path'].match('^/')
  node.set['tomcat']['logfiles_path'] = "/node['tomcat']['logfiles_path']"
end

###############################################################################
# End of default.rb
###############################################################################
