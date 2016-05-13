require 'azure_mgmt_compute'
require 'azure_mgmt_storage'
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)

::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)
::Chef::Recipe.send(:include, Azure::ARM::Storage)
::Chef::Recipe.send(:include, Azure::ARM::Storage::Models)

cloud_name = node['workorder']['cloud']['ciName']
compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']
# resource_group_name = compute_service['resource_group']
resource_group_name = node['platform-resource-group']
Chef::Log.info("Resource Group Name: #{resource_group_name}")

credentials = node['azureCredentials']
subscription = compute_service['subscription']
storage_client = StorageManagementClient.new(credentials)
storage_client.subscription_id = subscription

#This function will generate all possible storage account NAMES
#for current Resource Group.
def generate_storage_account_names(storage_account_name)
  #The max number of resources in a Resource Group is 800
  #Microsoft guidelines is 40 VM per storage account to not affect performance
  #So the most storage accounts we could have per Resource Group is 800/40

  limit = 800/40

  storage_accounts = Array.new

  (1..limit).each do |index|
    if index < 10
      account_name =  "#{storage_account_name}0" + index.to_s
    else
      account_name =  "#{storage_account_name}" + index.to_s
    end
    storage_accounts[index-1] = account_name
  end

  return storage_accounts
end

#Calculate the index of the storage account name array
#based on the number of virtual machines created on the
#current subscription
def calculate_storage_index(storage_accounts, vm_count)
  increment = 40
  storage_account = 0
  vm_count += 1
  storage_count = storage_accounts.size - 1

  (0..storage_count).each do |storage_index|
    storage_account += increment
    if vm_count <= storage_account
      return storage_index
    end
  end
  return -1
end

def get_subscription_vms(subscription, credentials)
  begin
    client = Azure::ARM::Compute::ComputeManagementClient.new(credentials)
    client.subscription_id = subscription
    promise = client.virtual_machines.list_all()
    result = promise.value!
    return result.body
  rescue  MsRestAzure::AzureOperationError => e
    OOLog.fatal(
      "Error getting subscription VMs: #{e.body.values[0]['message']}")
  rescue => ex
    OOLog.fatal("Error getting subscription VMs: #{ex.message}")
  end
end

#Get the total number of virtual machines created on the current subscription
def get_subscription_vm_count(subscription, credentials)
  vm_count = 0
  result = get_subscription_vms(subscription, credentials)
  vm_list = result.value
  if !vm_list.nil? and !vm_list.empty?
    vm_count = vm_list.size
  else
    vm_count = 0
  end
  return vm_count
end

def get_resource_group_vms(credentials, subscription, rg_name)
  begin
    client = Azure::ARM::Compute::ComputeManagementClient.new(credentials)
    client.subscription_id = subscription
    promise = client.virtual_machines.list(rg_name)
    result = promise.value!
    return result.body
  rescue  MsRestAzure::AzureOperationError => e
    OOLog.fatal("Error getting VMs from a resource group: #{e.body.values[0]['message']}")
  rescue => ex
    OOLog.fatal("Error getting VMs from a resource group: #{ex.message}")
  end
end

def get_resource_group_vm_count(credentials, subscription, rg_name)
  vm_count = 0
  result = get_resource_group_vms(credentials, subscription, rg_name)
  vm_list = result.value
  if !vm_list.nil? and !vm_list.empty?
    vm_count = vm_list.size
  else
    vm_count = 0
  end
  return vm_count
end

def storage_name_avail?(storage_client, storage_account_name)
  begin
     params = Azure::ARM::Storage::Models::StorageAccountCheckNameAvailabilityParameters.new
     params.name = storage_account_name
     params.type = 'Microsoft.Storage/storageAccounts'
     promise = storage_client.storage_accounts.check_name_availability(params)
     response = promise.value!
     result = response.body
     return result.name_available
   rescue  MsRestAzure::AzureOperationError => e
     Chef::Log.info("ERROR checking availability of #{storage_account_name}")
     Chef::Log.info("ERROR Body: #{e.body}")
     return nil
#    OOLog.fatal("Error checking availability of #{storage_account_name}: #{e.body.values[0]['message']}")
   rescue => ex
     OOLog.fatal("Error checking availability of #{storage_account_name}: #{ex.message}")
   end
end

def create_storage_account(storage_client, location, resource_group_name, storage_account_name, account_type)
  # Create a model for new storage account.
  properties = Azure::ARM::Storage::Models::StorageAccountPropertiesCreateParameters.new
  properties.account_type = account_type

  params = Azure::ARM::Storage::Models::StorageAccountCreateParameters.new
  params.properties = properties
  params.location = location

  begin
    Chef::Log.info("Creating Storage Account: [ #{storage_account_name} ] in Resource Group: #{resource_group_name} ...")
    start_time = Time.now.to_i
    promise = storage_client.storage_accounts.create(resource_group_name, storage_account_name, params)
    response = promise.value!
    result = response.body
    end_time = Time.now.to_i

    duration = end_time - start_time
    Chef::Log.info("Storage Account created in #{duration} seconds")

    return result
  rescue MsRestAzure::AzureOperationError => e
    OOLog.fatal("Error creating storage account: #{e.body.values[0]['message']}")
  rescue => ex
    OOLog.fatal("Error creating storage account: #{ex.message}")
  end
end

#==================================================
#Get the information from the workload in order to
#extract the platform name and generate
#the storage account name
workorder = node["workorder"]["rfcCi"]
nsPathParts = workorder["nsPath"].split("/")
org = nsPathParts[1]
assembly = nsPathParts[2]
platform = nsPathParts[5]

location = compute_service['location']
Chef::Log.info("Location: #{location}")


# Azure storage accout name restrinctions:
# alpha-numberic  no special characters between 9 and 24 characters

# name needs to be globally unique, but it also needs to be per region.
generated_name = "oostg" + node.workorder.box.ciId.to_s + Utils.abbreviate_location(location)

if generated_name.length > 22
  generated_name = generated_name.slice!(0..21)  #making sure we are not over the limit
end

Chef::Log.info("Generated Storage Account Name: #{generated_name}")
Chef::Log.info("Getting Resource Group '#{resource_group_name}' VM count")
vm_count = get_resource_group_vm_count(credentials, subscription, resource_group_name)
Chef::Log.info("Resource Group VM Count: #{vm_count}")

storage_accounts = generate_storage_account_names(generated_name)

storage_index = calculate_storage_index(storage_accounts, vm_count)
if storage_index < 0
  OOLog.fatal("***FAULT:FATAL=No storage account can be selected!")
end




storage_account_name = storage_accounts[storage_index]

#Check for Storage account availability(if storage account is created or not)
#Available means the storage account has not been created (need to create it)
#Otherwise, it is created and we can use it
if storage_name_avail?(storage_client, storage_account_name)
  #Storage account name is available; Need to create storage account

  #Select the storage according to VM size
  if node[:size_id] =~ /(.*)GS(.*)|(.*)DS(.*)/
    account_type = Azure::ARM::Storage::Models::AccountType::PremiumLRS
  else
    account_type = Azure::ARM::Storage::Models::AccountType::StandardLRS
  end

  OOLog.info("VM size: #{node[:size_id]}")
  OOLog.info("Storage Type: #{account_type}")

  storage_account = create_storage_account(storage_client, location, resource_group_name, storage_account_name, account_type)
  if storage_account.nil?
    OOLog.fatal("***FAULT:FATAL=Could not create storage account #{storage_account_name}")
  end
else
  Chef::Log.info("No need to create Storage Account: #{storage_account_name}")
end

msg = "***RESULT:Storage_Account_Name=#{storage_account_name}"
Chef::Log.info(msg)
# puts(msg)

Chef::Log.info("ImageID: #{node['image_id']}")

# image_id is expected to be in this format; Publisher:Offer:Sku:Version (ie: OpenLogic:CentOS:6.6:latest)
imageID = node['image_id'].split(':')

# build storage profile to add to the params for the vm
storage_profile = StorageProfile.new
storage_profile.image_reference = ImageReference.new
storage_profile.image_reference.publisher = imageID[0]
storage_profile.image_reference.offer = imageID[1]
storage_profile.image_reference.sku = imageID[2]
storage_profile.image_reference.version = imageID[3]
Chef::Log.info("Image Publisher is: #{storage_profile.image_reference.publisher}")
Chef::Log.info("Image Sku is: #{storage_profile.image_reference.sku}")
Chef::Log.info("Image Offer is: #{storage_profile.image_reference.offer}")
Chef::Log.info("Image Version is: #{storage_profile.image_reference.version}")

image_version_ref = storage_profile.image_reference.offer+"-"+(storage_profile.image_reference.version).to_s
msg = "***RESULT:Server_Image_Name=#{image_version_ref}"
Chef::Log.info(msg)

server_name = node['server_name']
Chef::Log.info("Server Name: #{server_name}")

storage_profile.os_disk = Azure::ARM::Compute::Models::OSDisk.new
storage_profile.os_disk.name = "#{server_name}-disk"
Chef::Log.info("Disk Name is: '#{storage_profile.os_disk.name}' ")

storage_profile.os_disk.vhd = Azure::ARM::Compute::Models::VirtualHardDisk.new
storage_profile.os_disk.vhd.uri = "https://#{storage_account_name}.blob.core.windows.net/vhds/#{storage_account_name}-#{server_name}.vhd"
Chef::Log.info("VHD URI is: #{storage_profile.os_disk.vhd.uri}")
storage_profile.os_disk.caching = Azure::ARM::Compute::Models::CachingTypes::ReadWrite
storage_profile.os_disk.create_option = Azure::ARM::Compute::Models::DiskCreateOptionTypes::FromImage

disk_size_map = JSON.parse(compute_service['ephemeral_disk_sizemap'] )
vm_size = node['workorder']['rfcCi']['ciAttributes']['size']
Chef::Log.info("data disk size from size map: #{disk_size_map[vm_size]} ")
#if the VM exists already data disk property need not be updated. Updating the datadisk size will result in an error.

if node.VM_exists == false

  #Add a data disk
  data_disk1 = DataDisk.new
  data_disk1.name = "#{server_name}-datadisk"
  data_disk1.lun = 0
  data_disk1.disk_size_gb = disk_size_map[vm_size]
  data_disk1.vhd = VirtualHardDisk.new
  data_disk1.vhd.uri = "https://#{storage_account_name}.blob.core.windows.net/vhds/#{storage_account_name}-#{server_name}-data1.vhd"
  data_disk1.caching = CachingTypes::ReadWrite
  data_disk1.create_option = DiskCreateOptionTypes::Empty
  storage_profile.data_disks = Array.[](data_disk1)
  Chef::Log.info("Data Disk Name is: '#{data_disk1.name}' ")
  Chef::Log.info("Data Disk VHD URI is: #{data_disk1.vhd.uri}")
end
node.set['storageProfile'] = storage_profile

Chef::Log.info("Exiting azure storage profile")
