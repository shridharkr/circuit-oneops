# a little recipe that sets the platform, platform-resource-group and platform-availability-set for azure deployments.
# several other recipes use this

require File.expand_path('../../libraries/regions.rb', __FILE__)

def generate_rg_name(org,assembly,platform,environment,location)
  Chef::Log.info("Resource Group org: #{org}")
  Chef::Log.info("Resource Group assembly: #{assembly}")
  Chef::Log.info("Resource Group Platform: #{platform}")
  Chef::Log.info("Resource Group Environment: #{environment}")
  Chef::Log.info("Resource Group location: #{location}")
  resource_group_name = org + '-' + assembly + '-' + platform + '-' + environment + '-' + location
  Chef::Log.info("platform-resource-group is: #{resource_group_name}")
  Chef::Log.info("Resource Group Name Length = #{resource_group_name.length}")

  #Maximum length of Azure Resource Group Name is 90 characters
   if (resource_group_name.length > 90)
     Chef::Log.info("Resource Group Name is more 90 characters long...Will need to trim it down.")
     resource_group_name = org[0..15] + '-' + assembly[0..15] + '-' + node.workorder.box.ciId.to_s + '-' + environment[0..15] + '-' + AzureRegions::RegionName.abbreviate(location)
  end
  Chef::Log.info("New Resource Group Name = #{resource_group_name}")
  Chef::Log.info("New Resource Group Name Length = #{resource_group_name.length}")
  return resource_group_name
end

Chef::Log.info("get_platform_rg_and_as.rb called from " )
Chef::Log.info(node.run_list[0])
  node.run_list.each {
        |recipe|
 if recipe == "recipe[compute::status]" || recipe == "recipe[compute::reboot]" || recipe == "recipe[compute::powercycle]"
    ci = node['workorder']['ci']
    cloud_name = node['workorder']['cloud']['ciName']
    Chef::Log.info('cloud_name is: ' + cloud_name)
    compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']
    Chef::Log.debug("ci attrs:"+ci['ciAttributes'].inspect.gsub("\n"," "))

    metadata = ci['ciAttributes']['metadata']
    node.set['vm_name'] = ci['ciAttributes']['instance_name']
    metadata_obj= JSON.parse(metadata)
    org = metadata_obj['organization']
    assembly = metadata_obj['assembly']
    platform = metadata_obj['platform']
    env = metadata_obj['environment']
    location = compute_service['location']
    node.set['subscriptionid']=compute_service['subscription']
    resource_group_name = generate_rg_name(org,assembly,platform,environment,location)
    node.set['platform-resource-group'] = resource_group_name
    return true
end
}



app_type = node['app_name']

cloud_name = node['workorder']['cloud']['ciName']


if app_type == 'lb'
  location = node.workorder.services['lb'][cloud_name][:ciAttributes][:location]
else
  # location = node['workorder']['services']['compute'][cloud_name]['ciAttributes']['location']
  location = node.workorder.services['compute'][cloud_name][:ciAttributes][:location]
end


if location.nil?
  msg = "Azure location/region not found"
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  raise(msg)
end

keypair = node["workorder"]["rfcCi"]
nsPathParts = keypair["nsPath"].split("/")
org = nsPathParts[1]
assembly = nsPathParts[2]
environment = nsPathParts[3]
platform = nsPathParts[5]
resource_group_name = generate_rg_name(org,assembly,platform,environment,location)
node.set['platform-resource-group'] = resource_group_name
node.set['platform-availability-set'] = resource_group_name
node.set['platform'] = platform
