
def whyrun_supported?
  true
end

action :create do
  rg_manager = AzureBase::ResourceGroupManager.new(@new_resource.node)
  rg_manager.add()

  @new_resource.updated_by_last_action(true)
end

action :destroy do
  rg_manager = AzureBase::ResourceGroupManager.new(@new_resource.node)
  rg_manager.delete()

  @new_resource.updated_by_last_action(true)
end