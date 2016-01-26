# cassandra replace

include_recipe 'cassandra::install_software'


ruby_block "replace_address option" do
  block do
    
    node.set["cassandra_replace_option"] = "-Dcassandra.replace_address=#{node.workorder.rfcCi.ciAttributes.node_ip}"
    
  end
end
 
include_recipe "cassandra::add"
