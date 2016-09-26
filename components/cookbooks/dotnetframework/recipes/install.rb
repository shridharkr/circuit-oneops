if node['platform_family'] == 'windows'

  CHEF_VERSION_EXPRESSION = /^Chef:\s(?<major>\d\d)\.(?<minor>\d{1}+)\.(?<patch>\d{1}+)$/
  capture = CHEF_VERSION_EXPRESSION.match(`chef-client -v`.chomp)

  if capture['major'].to_i >= 12 && capture['minor'].to_i >= 7

    dotnet_version_package_name = JSON.parse(node.dotnetframework.dotnet_version_package_name)
    dotnet_version_package_name.each do |dotnet_version,package_name|
      Chef::Log.info("installing #{dotnet_version}")
      chocolatey_package package_name do
        source node.dotnetframework.chocolatey_package_source
        options "--ignore-package-exit-codes=3010"
        action :install
      end
    end

  else
    Chef.Log.fatal("Please upgrade your chef client as chocolatey_package resource only available in version >= 12.7")
  end

else
  Chef.Log.fatal(".net framework not supported on #{node['platform_family']}")
end
