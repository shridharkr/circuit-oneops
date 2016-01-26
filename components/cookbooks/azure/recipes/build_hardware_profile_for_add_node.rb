require 'azure_mgmt_compute'

::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)

# build hardware profile to add to the params for the vm
hardware_profile = HardwareProfile.new
hardware_profile.vm_size = node['size_id']

Chef::Log.info('VM Size is: ' + hardware_profile.vm_size)

node.set['hardwareProfile'] = hardware_profile

Chef::Log.info("Exiting hardware profile")
