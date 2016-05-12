# Support whyrun
def whyrun_supported?
  true
end

action :create do
    rg_manager = AzureBase::ResourceGroupManager.new(@new_resource.node)
    rg_manager.add
end
