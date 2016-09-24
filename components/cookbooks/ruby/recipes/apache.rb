pkgs = value_for_platform(
  %w(centos redhat fedora) => {'default' => []},
  %w(debian ubuntu)        => {'default' => %w(libapache2-mod-passenger)},
  'default'                => %w(libapache2-mod-passenger)
)

pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

passenger_version = '4.0.59'

case node[:platform]
  when 'centos', 'redhat', 'fedora', 'suse', 'arch'
    conf_file    = '/etc/httpd/conf.d/passenger'
    service_name = 'httpd'
  when 'debian', 'ubuntu'
    conf_file    = '/etc/apache2/conf.d/passenger'
    service_name = 'apache2'
  else
    message = "Unsupported platform: #{node[:platform]}"
    Chef::Log.error(message)
    raise Exception.new(message)
end

bash 'install passenger' do
  script = ''
  if node[:ruby][:install_type] == 'rvm'
    script += <<-EOH
      source /usr/local/rvm/scripts/rvm
      rvm use #{node[:ruby][:version]}
    EOH
  end

  script += <<-EOH
    GEM_DIR=`gem env gemdir`/gems/passenger-#{passenger_version}
    RUBY_BIN=`which ruby | tail -1`
    gem install passenger --version=#{passenger_version} --no-ri --no-rdoc
    $GEM_DIR/bin/passenger-install-apache2-module -a
    echo "LoadModule passenger_module /usr/local/share/gems/gems/passenger-#{passenger_version}/buildout/apache2/mod_passenger.so" > #{conf_file}
    echo "PassengerRoot /usr/local/share/gems/gems/passenger-#{passenger_version}" >> #{conf_file}
    echo "PassengerRuby $RUBY_BIN" >> #{conf_file}
  EOH

  Chef::Log.info("Script to install passenger:\n#{script}")

  code script
end

service service_name do
  action :restart
end
