
# class AzureResources
#   class ResourceGroup < Chef::Resource
#
#     provides :resource_group
#
#     def initialize(name, run_context=nil)
#       super
#       @resource_name = :resource_group
#       @allowed_actions = [:add, :delete]
#       @action = :add  #default action
#
#       #set resource defaults
#       @name = name
#     end
#
#     # Getter and Setters for attributes
#     def name(arg=nil)
#       set_or_return(:name, arg, :kind_of => String)
#     end
#
#   end
# end
