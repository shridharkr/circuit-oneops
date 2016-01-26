require 'azure_mgmt_storage'

::Chef::Recipe.send(:include, Azure::ARM::Storage)
::Chef::Recipe.send(:include, Azure::ARM::Storage::Models)

cloud_name = node['workorder']['cloud']['ciName']
Chef::Log.info("Cloud Name: #{cloud_name}")
compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']
Chef::Log.info("initial UserName:"+ compute_service['initial_user'])
node.set['initial_user']=compute_service['initial_user']
# build the OS profile to add to the params for the VM
# get the keypair to add to the VM for the oneops user
# this is the user that will be used to communicate with the VM
keypair = node['workorder']['payLoad']['SecuredBy'].first
linux_config = LinuxConfiguration.new
linux_config.disable_password_authentication = true
linux_config.ssh = SshConfiguration.new
linux_config.ssh.public_keys = []
linux_config.ssh.public_keys[0] = SshPublicKey.new
linux_config.ssh.public_keys[0].path = '/home/'+compute_service['initial_user']+'/.ssh/authorized_keys'
linux_config.ssh.public_keys[0].key_data = keypair['ciAttributes']['public']

Chef::Log.info('Public Key is: ' + keypair['ciAttributes']['public'])

os_profile = OSProfile.new
os_profile.computer_name = node['server_name']
Chef::Log.info('Computer Name is: ' + os_profile.computer_name)
os_profile.admin_username = compute_service['initial_user']
os_profile.linux_configuration = linux_config

node.set['osProfile'] = os_profile

Chef::Log.info("Exiting azure os profile")
