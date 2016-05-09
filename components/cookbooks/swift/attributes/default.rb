cloud_name = node.workorder.cloud.ciName
cloud_service = node.workorder.services["filestore"][cloud_name]
default[:swift][:tenant] = cloud_service[:ciAttributes][:tenant]
default[:swift][:endpoint] = cloud_service[:ciAttributes][:endpoint]
default[:swift][:username] = node.workorder.rfcCi.ciAttributes[:username]
default[:swift][:password] = node.workorder.rfcCi.ciAttributes[:password]
default[:swift][:authstrategy] = cloud_service[:ciAttributes][:authstrategy]
default[:swift][:homepath]= '/etc'
default[:swift][:platform] = 'rhel'
for entry in node.workorder.payLoad.DependsOn
  if entry.ciAttributes.has_key?("home_directory")
    default[:swift][:homepath]=entry.ciAttributes[:home_directory]
  end
end
case platform_family
  when 'debian'
    default[:swift][:platform] = {
	'swift_client_packages' => ['python-swiftclient', 'python-keystoneclient'],
	'override_options' => "-o Dpkg::Options:='--force-confold' -o Dpkg::Option:='--force-confdef'"
  }
  when 'rhel'
    default[:swift][:platform] = {
        'swift_client_packages' => ['python-swiftclient', 'python-keystoneclient'],
        'override_options' => ""
  }
end
