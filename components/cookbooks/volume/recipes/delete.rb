# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# volume::delete
#
# unmounts, removes: raid, lv vg and detaches blockstorage
#

has_mounted = false

rfcAttrs = node.workorder.rfcCi.ciAttributes
if rfcAttrs.has_key?("mount_point") &&
   !rfcAttrs["mount_point"].empty?

  mount_point = rfcAttrs["mount_point"].gsub(/\/$/,"")

  log "umount_point" do
    message "umount directory is: #{mount_point}"
    level :info
  end


  `grep #{mount_point} /etc/mtab`
  if $? == 0
    has_mounted = true
  end

  case node[:platform]
  when "centos","redhat","fedora","suse"
    package "lsof"
  end

  execute "lsof #{mount_point} | awk '{print $2}' | grep -v PID | uniq | xargs kill -9; umount #{mount_point}" do
    only_if { has_mounted }
  end

# clear the tmpfs ramdisk entries from /etc/fstab
 if(rfcAttrs["fstype"] == "tmpfs")
    Chef::Log.info("clearing /etc/fstab entry for fstype tmpfs")
    result = `grep -v #{mount_point} /etc/fstab > /tmp/fstab`
    `mv /tmp/fstab /etc/fstab`
  end
end


ruby_block 'lvremove ephemeral' do
  block do

    platform_name = node.workorder.box.ciName
    if ::File.exists?("/dev/#{platform_name}-eph/#{node.workorder.rfcCi.ciName}")

      cmd = "lvremove -f #{platform_name}-eph/#{node.workorder.rfcCi.ciName}"
      Chef::Log.info("running: #{cmd} ...")
      out = `#{cmd}`
      if $? != 0
        Chef::Log.error("error in lvremove: #{out}")
        exit 1
      end
    end

  end
end

supported = true

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

include_recipe "shared::set_provider"


ruby_block 'lvremove storage' do
  block do
    
    unless storage.nil? 
        
      platform_name = node.workorder.box.ciName
      
      cmd = "lvremove -f #{platform_name}"
      Chef::Log.info("running: #{cmd}...")
      out = `#{cmd}`
    
      raid_device = "/dev/md/"+ node.workorder.rfcCi.ciName
      retry_count = 0
      max_retry_count = 3
    
      if provider_class =~ /rackspace/
        Chef::Log.info "no raid for rackspace"
      else
        while retry_count < max_retry_count && ::File.exists?(raid_device) do
          `mdadm --stop #{raid_device}`
          `mdadm --remove #{raid_device}`
          retry_count += 1
          if ::File.exists?(raid_device)
            Chef::Log.info("waiting 10sec for raid array to stop/remove")
            sleep 10
          end
        end
    
        if ::File.exists?(raid_device)
          Chef::Log.error("raid device still exists after many mdadm --stop "+raid_device)
          exit 1
        end
      end
        
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
          elsif provider_class =~ /azure/
            Chef::Log.info( "azure blobs will be detached in the storage step")
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
  
    end

  end
end
