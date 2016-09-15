# rubocop:disable LineLength
###############################################################################
# Tomcat defaults from metadata.rb
###############################################################################
#default['tomcat']['version'] = '8.5.2'
default['tomcat']['port'] = 8080
default['tomcat']['ssl_port'] = 8443
default['tomcat']['java_options'] = '-Djava.awt.headless=true -Djavax.net.ssl.trustStore="/opt/tomcat/ssl/trust.jks"'
default['tomcat']['webapp_install_dir'] = '/opt/tomcat/webapps'
default['tomcat']['stop_time'] = 45
default['tomcat']['max_threads'] = 50
default['tomcat']['min_spare_threads'] = 25
default['tomcat']['tomcat_user'] = 'tomcat'
default['tomcat']['tomcat_group'] = 'tomcat'
default['tomcat']['logfiles_path'] = '/opt/tomcat/logs'

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
set['tomcat']['config_dir'] = '/opt/tomcat'
set['tomcat']['tmp_dir'] = '/var/cache/tomcat/temp'
set['tomcat']['work_dir'] = '/var/cache/tomcat/work'
set['tomcat']['context_dir'] = "#{tomcat['config_dir']}/Catalina/localhost"
if !node['tomcat']['logfiles_path'].match('^/')
  node.set['tomcat']['logfiles_path'] = "/node['tomcat']['logfiles_path']"
end

###############################################################################
# End of default.rb
###############################################################################
