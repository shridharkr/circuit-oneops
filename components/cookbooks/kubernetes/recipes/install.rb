pkg_url = node['kube']['package']
pkg_name = ::File.basename(pkg_url)
download_dir = '/root'

# download kubernetes package
remote_file "#{download_dir}/#{pkg_name}" do
  source pkg_url
end

# extract kubernetes package
execute "extract package #{pkg_name}" do
  cwd download_dir
  command "tar xf #{pkg_name} && tar xf kubernetes/server/kubernetes-server-linux-amd64.tar.gz"
end

# copy kubernetes bin to /usr/bin dir
execute 'copy kubernetes to /usr/bin dir' do
  cwd download_dir
  command '/bin/cp -rf kubernetes/server/bin/kube* /usr/bin/'
end

# create kube user
user 'create kube user' do
  username 'kube'
  comment 'kubernetes user'
  home '/var/lib/kubelet'
  shell '/usr/sbin/nologin'
  supports manage_home: true
end

# create /etc/kubernetes directory
directory '/etc/kubernetes' do
  owner 'root'
  group 'root'
  mode 00755
  action :create
end
  