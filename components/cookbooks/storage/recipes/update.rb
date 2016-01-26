Chef::Log.info("Storage Update .......")

v_device_map = node.workorder.rfcCi.ciAttributes["device_map"]

 Chef::Log.info("----------------------------------------------------")
 Chef::Log.info("Device Map : <"+v_device_map.to_s+">")
 Chef::Log.info("----------------------------------------------------")

 #If Storage is not Allocated the Only Call Storage Add else Do Nothing
  if v_device_map.nil?
    include_recipe 'storage::add'
  end

