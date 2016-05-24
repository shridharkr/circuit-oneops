
#set the proxy if it exists as a cloud var
Utils.set_proxy(node[:workorder][:payLoad][:OO_CLOUD_VARS])

# create the resource group
azurekeypair_resource_group 'Resource Group' do
  action :destroy
end


OOLog.info('Exiting delete keypair')