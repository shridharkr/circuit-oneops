if node.platform == 'windows'
  artifact_directory = node[:artifact][:install_dir] || 'c:\platform_artifact'
  package_dir = ::File.join(node[:artifact][:install_dir], [node[:artifact][:name], node[:artifact][:version]].join('.'))
  directory package_dir do
    action :delete
    only_if ::File.exists?(package_dir)
  end
else
  #removing the older artifact binaries to cleanup disk. This is a temporary code until we get rid of disk space issue for some applications
  Chef::Log.info("deleting all older versions from under #{node[:artifact][:install_dir]}/artifact_deploys/")
  execute "rm -rf #{node[:artifact][:install_dir]}/artifact_deploys/*"
end
include_recipe "artifact::update"
