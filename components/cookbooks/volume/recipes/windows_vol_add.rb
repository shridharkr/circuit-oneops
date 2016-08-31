 storage = nil
 node.workorder.payLoad[:DependsOn].each do |dep|
   if dep["ciClassName"] =~ /Storage/
      storage = dep
      break
    end
  end
  
storage = nil
 node.workorder.payLoad[:DependsOn].each do |dep|
   if dep["ciClassName"] =~ /Storage/
      storage = dep
      break
    end
  end

  cloud_name = node[:workorder][:cloud][:ciName]
include_recipe "shared::set_provider"
vol_size =  node.workorder.rfcCi.ciAttributes[:size]
 Chef::Log.error("-------------------------------------------------------------")
 Chef::Log.error("Volume Size : "+vol_size )
 Chef::Log.error("-------------------------------------------------------------")
vol = nil
dev_id = nil
vol_id = nil
if node.workorder.rfcCi.ciAttributes[:size] == "-1"
  Chef::Log.error("skipping because size = -1")
  return
end

cloud_name = node[:workorder][:cloud][:ciName]
token_class = node[:workorder][:services][:compute][cloud_name][:ciClassName].split(".").last.downcase
include_recipe "shared::set_provider"

storage_provider = node.storage_provider_class

 provider = node[:iaas_provider]
        storage_provider = node[:storage_provider]

        instance_id = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["instance_id"]
        Chef::Log.error("instance_id: "+instance_id)
        compute = provider.servers.get(instance_id)

      device_maps = storage['ciAttributes']['device_map'].split(" ")
      vols = Array.new
      dev_list = ""
      i = 0
      device_maps.each do |dev_vol|
        vol_id = dev_vol.split(":")[0]
        dev_id = dev_vol.split(":")[1]
        Chef::Log.error("vol_id: "+vol_id)
        Chef::Log.error("provider: "+provider.inspect())
        vol = provider.volumes.get vol_id 
      end        
      case token_class
         when /openstack/
            if vol.attachments != nil && vol.attachments.size > 0 &&
              vol.attachments[0]["serverId"] == instance_id
              Chef::Log.error("attached already, no way to determine device")
            else
              begin
              # determine new device by by watching /dev because openstack (kvm) doesn't attach it to the specified device
                  vol.attach instance_id,dev_id

              rescue Exception => e
                      Chef::Log.error("error attaching volume to the VM"+e.inspect())
              end
           end
           end
         
Chef::Log.error("-------------------------------------------")
Chef::Log.error("dev_id: "+dev_id)
Chef::Log.error("Instance_id: "+instance_id)


powershell_script "run add_disk script" do
  code "c:/cygwin64/home/admin/circuit-oneops-1/components/cookbooks/volume/files/add_disk.ps1"
end 



