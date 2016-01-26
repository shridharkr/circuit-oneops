ruby_repository "brightbox" do
  uri "http://apt.brightbox.net"
  distribution node['lsb']['codename']
  components ["main"]
  key "http://apt.brightbox.net/release.asc"
  # keyserver "wwwkeys.eu.pgp.net"
  action :add
end

pkgs = value_for_platform(
  [ "centos", "redhat", "fedora" ] => {
    "default" => %w{ }
  },
  [ "debian", "ubuntu" ] => {
    "default" => %w{ libapache2-mod-passenger }
  },
  "default" => %w{ libapache2-mod-passenger }
)

pkgs.each do |pkg|
  package pkg do
    action :install
  end
end


passenger_version = '4.0.59'

if node[:ruby][:install_type] == 'rvm'

  ruby_version = node[:ruby][:version]

  ruby_bin = "/usr/local/rvm/wrappers/ruby-#{ruby_version}/ruby"
  gems_dir = "/usr/local/rvm/gems/ruby-#{ruby_version}/gems"

  bash "install passenger" do
    code <<-EOH
      source /usr/local/rvm/scripts/rvm
      rvm use #{ruby_version}
      gem install passenger --version=#{passenger_version} --no-ri --no-rdoc
      passenger-install-apache2-module -a
    EOH
  end

else

  ruby_bin = '/usr/bin/ruby'
  gems_dir = '/usr/lib/ruby/gems/1.8/gems'

  bash "install passenger" do
    code <<-EOH
      /usr/bin/gem install passenger --version=#{passenger_version} --no-ri --no-rdoc
      /usr/bin/passenger-install-apache2-module -a
    EOH
  end

end

passenger_content = "LoadModule passenger_module #{gems_dir}/passenger-#{passenger_version}/buildout/apache2/mod_passenger.so\n"
passenger_content += "PassengerRoot #{gems_dir}/passenger-#{passenger_version}\n"
passenger_content += "PassengerRuby #{ruby_bin}\n"


case node[:platform]
when "centos","redhat","fedora","suse","arch"
  file "/etc/httpd/conf.d/passenger" do
    content passenger_content
  end
  service "httpd" do
    action :restart
  end
when "debian","ubuntu"
  file "/etc/apache2/conf.d/passenger" do
    content passenger_content
  end
  service "apache2" do
    action :restart
  end
end
