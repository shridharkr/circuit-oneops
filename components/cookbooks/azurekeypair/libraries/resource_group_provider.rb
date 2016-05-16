
# class AzureResources
#   class ResourceGroup < Chef::Provider
#
#     def whyrun_supported?
#       true
#     end
#
#     # Mandatory for providers
#     def load_current_resource
#       @current_resource = Chef::Resource::ResourceGroup.new(new_resource.name)
#     end
#
#     def action_add
#       Chef::Log.info("Add action called")
#     end
#
#     def action_delete
#       Chef::Log.inf("Delete action called")
#     end
#
#   end
# end

