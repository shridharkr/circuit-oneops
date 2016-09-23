case node['platform_family']
when 'windows'

  dotnet = node[:workorder][:rfcCi][:ciAttributes]
  dotnet_package_name = dotnet[:dotnet_framework_version]
  dotnet_package_source = dotnet[:chocolatey_package_source]

  chocolatey dotnet_package_name do
    source dotnet_package_source
    options ({ '-ignore-package-exit-codes' => "" })
    action :install
  end

else

  log ".net framework not supported on #{node['platform_family']}" do
    level :warn
  end

end
