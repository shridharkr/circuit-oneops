
download_dir = '/opt'



# skip install if installed
installed = false
version_file = "#{download_dir}/kubernetes/version"
if File.exists?(version_file)
  version = File.read(version_file)
  Chef::Log.info("found existing installed version: #{version}")
  if version.gsub("\n","") == "v#{node.workorder.rfcCi.ciAttributes.version}"
    installed = true
  end
end

unless installed

  # default to public, override using mirror cloud service
  mirror = "https://github.com/GoogleCloudPlatform"
  cloud_name = node.workorder.cloud.ciName
  if node.workorder.services.has_key?("mirror") &&
     node.workorder.services.mirror[cloud_name]['ciAttributes']['mirrors'].include?('kubernetes')
    
    mirrors = JSON.parse(node.workorder.services.mirror[cloud_name]['ciAttributes']['mirrors'])
    if mirrors.has_key?("kubernetes")
      mirror = mirrors['kubernetes']    
      Chef::Log.info("using mirrors payload: #{mirror}")
    end
    
  end
  pkg_name = "kubernetes.tar.gz"
  pkg_url = mirror+"/kubernetes/releases/download/v#{node.workorder.rfcCi.ciAttributes.version}/#{pkg_name}"  
  
  # download kubernetes package
  download_args = ''
  if node.kubernetes.has_key?('download_args')
    download_args = JSON.parse(node.kubernetes.download_args).join(' ')
  end
  execute "wget #{download_args} #{pkg_url} -O #{download_dir}/#{pkg_name}"
  
  # extract kubernetes package
  execute "extract package #{pkg_name}" do
    cwd download_dir
    command "tar xf #{pkg_name} && tar xf kubernetes/server/kubernetes-server-linux-amd64.tar.gz"
  end
  
  # copy kubernetes bin to /usr/bin dir
  execute 'copy kubernetes to /usr/bin dir' do
    cwd download_dir
    command '/bin/cp -rf kubernetes/server/bin/kube* /usr/bin/ ; chmod a+x /usr/bin/kube* ; rm -fr kubernetes/server ; rm -fr kubernetes/platforms '
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
end
  