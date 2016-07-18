

# PCRE build
pcre_base_url = "ftp://ftp.csx.cam.ac.uk/pub/software/programming/"
pcre_version = "8.37"
pcre_tarball = "pcre-#{pcre_version}.tar.bz2"
pcre_tarball_download = pcre_base_url + "pcre/" + "#{pcre_tarball}"


remote_file ::File.join(Chef::Config[:file_cache_path], "#{pcre_tarball}") do
    source pcre_tarball_download
    mode "0644"
    action :create
    owner "root"
    not_if { ::File.exists?("#{Chef::Config[:file_cache_path]}/pcre-#{pcre_version}") }
end

bash "build-pcre" do
    cwd Chef::Config[:file_cache_path]
    code <<-EOF
      tar xfvj pcre-#{pcre_version}.tar.bz2
      cd pcre-#{pcre_version} && ./configure && /usr/bin/make
    EOF
    not_if { ::File.exists?("#{Chef::Config[:file_cache_path]}/pcre-#{pcre_version}") }
end


# nginx build and install
nginx_base_url = "http://nginx.org/download/"
nginx_version = "1.7.6"
nginx_tarball = "nginx-#{nginx_version}.tar.gz"
nginx_tarball_download = nginx_base_url + "#{nginx_tarball}"
install_path = "/opt/nginx"

remote_file ::File.join(Chef::Config[:file_cache_path], "#{nginx_tarball}") do
    source nginx_tarball_download
    mode "0644"
    action :create
    owner "root"
    not_if { ::File.exists?(install_path) }
end

bash "build-and-install-nginx" do
    cwd Chef::Config[:file_cache_path]
    code <<-EOF
      tar xfvz nginx-#{nginx_version}.tar.gz
      cd nginx-#{nginx_version} && ./configure --with-pcre='#{Chef::Config[:file_cache_path]}/pcre-#{pcre_version}' --prefix=#{install_path} --with-debug && /usr/bin/make && /usr/bin/make install
    EOF
    not_if { ::File.exists?(install_path) }
end


# uwsgi build and install
uwsgi_base_url = "https://github.com/unbit/uwsgi/archive/"
uwsgi_version = "2.0.13"
uwsgi_tarball = "uwsgi-#{uwsgi_version}.tar.gz"
uwsgi_tarball_download = uwsgi_base_url + "#{uwsgi_version}.tar.gz"
install_path = "/opt/uwsgi"

remote_file ::File.join(Chef::Config[:file_cache_path], "#{uwsgi_tarball}") do
    source uwsgi_tarball_download
    mode "0644"
    action :create
    owner "root"
    not_if { ::File.exists?(install_path) }
end

bash "build-and-install-uwsgi" do
    cwd Chef::Config[:file_cache_path]
    code <<-EOF
      tar xfvz uwsgi-#{uwsgi_version}.tar.gz
      cd uwsgi-#{uwsgi_version} && /usr/bin/make
      mkdir -p #{install_path}/{sbin,apps}
      cp uwsgi #{install_path}/sbin/
    EOF
    not_if { ::File.exists?(install_path) }
end

directory "/opt/uwsgi/log" do
    owner "root"
    group "root"
    mode "0755"
    action :create
end

# prep graphite support directories
directory "/opt/graphite/storage/log/webapp" do
    owner "apache"
    group "apache"
    mode "0755"
    action :create
end

# config files
include_recipe "graphite::nginx_graphite_configs"
