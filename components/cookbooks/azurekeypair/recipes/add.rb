
#set the proxy if it exists as a cloud var
Utils.set_proxy(node[:workorder][:payLoad][:OO_CLOUD_VARS])

# create the resource group
azurekeypair_resource_group 'Resource Group' do
  action :create
end


# create the availability set
azurekeypair_availability_set 'Availability Set' do
  action :create
end


OOLog.info('Exiting add keypair')
