# Class to handle the hardware profile for the azure compute.
# Nothing much happening here, just setting the vm size on the hardware profile for now.

module AzureCompute
  class HardwareProfile

    def build_profile(vm_size)
      hardware_profile = Azure::ARM::Compute::Models::HardwareProfile.new
      hardware_profile.vm_size = vm_size
      hardware_profile
    end

  end
end
