powershell_script "run del_disk script" do
  code "c:/cygwin64/home/admin/circuit-oneops-1/components/cookbooks/volume/files/del_disk.ps1"
end 

cloud_name = node[:workorder][:cloud][:ciName]
provider_class = node[:workorder][:services][:compute][cloud_name][:ciClassName].split(".").last.downcase
Chef::Log.info("provider: #{provider_class}")
if provider_class =~ /virtualbox|vagrant|docker/
  Chef::Log.info(" virtail box vegrant and docker don't support iscsi/ebs via api yet - skipping")
  supported = false
end

storage = nil
node.workorder.payLoad.DependsOn.each do |dep|
  if dep["ciClassName"] =~ /Storage/
    storage = dep
    break
  end
end

if storage == nil
  Chef::Log.info("no DependsOn Storage.")
end
retry_count = 0
      max_retry_count = 3
include_recipe "shared::set_provider"
provider = node.iaas_provider
      storage_provider = node.storage_provider
    
      instance_id = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["instance_id"]
      Chef::Log.info("instance_id: "+instance_id)

      device_maps = storage['ciAttributes']['device_map'].split(" ")
      change_count = 1
      retry_count = 0
      while change_count > 0 && retry_count < max_retry_count
        change_count = 0
    
          device_maps.each do |dev_vol|

          vol_id = dev_vol.split(":")[0]
          dev_id = dev_vol.split(":")[1]
          Chef::Log.info("vol: "+vol_id)
           if provider_class =~ /rackspace|ibm/
            volume = storage_provider.volumes.get vol_id
          else
            volume = provider.volumes.get  vol_id
          end
          Chef::Log.info( "volume:"+volume.inspect.gsub("\n",""))

          begin
            if provider_class =~ /openstack/
              vol_state = volume.status.downcase
            else
              vol_state = volume.state.downcase
            end
            
            if vol_state != "available" && vol_state != "detached"
              if vol_state != "detaching"
                Chef::Log.info("detaching "+vol_id)
                
                case provider_class
                when /openstack/
                  attached_instance_id = ""
                  if volume.attachments.size >0
                     attached_instance_id = volume.attachments[0]["serverId"]
                  end
                  
                  if attached_instance_id != instance_id
                     Chef::Log.info("attached_instance_id: #{attached_instance_id} doesn't match this instance_id: "+instance_id)
                  else
                    volume.detach instance_id, vol_id
                    sleep 10
                    detached=false
                    detach_wait_count=0
                    while !detached && detach_wait_count<max_retry_count do
                      volume = provider.volumes.get vol_id
                      Chef::Log.info("vol state: "+volume.status)
                      if volume.status == "available"
                        detached=true
                      else
                        sleep 10
                        detach_wait_count += 1
                      end
                   end
    
                  end
    
                when /rackspace/
                  compute = provider.servers.get instance_id
                  compute.attachments.each do |a|
                     Chef::Log.info "destroying: "+a.inspect
                     a.destroy
                  end
                when /ibm/
                  compute = provider.servers.get instance_id
                  compute.detach(volume.id)
                else
                  # aws uses server_id
                  if volume.server_id == instance_id
                    volume.server = nil
                  else
                     Chef::Log.info("attached_instance_id: #{volume.server_id} doesn't match this instance_id: "+instance_id)
                  end
                end
    
              end
              change_count += 1
            else
              Chef::Log.info( "volume available.")
            end
          rescue  => e
            Chef::Log.error("exception: "+e.message + "\n" + e.backtrace.inspect)
          end
        end
    
        Chef::Log.info("this pass detach count: #{change_count}")
        if change_count > 0
          retry_sec = retry_count*10
          Chef::Log.info( "sleeping "+retry_sec.to_s+" sec...")
          sleep(retry_sec)
        end
        retry_count += 1
      end
  
   

 