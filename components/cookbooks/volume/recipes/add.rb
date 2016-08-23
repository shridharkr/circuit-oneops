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

#
# volume::delete
#

# scan for available /dev/xvd* devices from dmesg
# create a physical device in LVM (pvcreate) for each
# create a volume group vgcreate with the name of the platform
# create a logical volume lvcreate with the name of the resource /dev/<resource>
# use storage dep to gen a raid and lvm ontop

package "lvm2"
package "mdadm"

include_recipe "shared::set_provider"

storage = nil
node.workorder.payLoad[:DependsOn].each do |dep|
  if dep["ciClassName"] =~ /Storage/
    storage = dep
    break
  end
end

cloud_name = node[:workorder][:cloud][:ciName]
newDevicesAttached = ""
mode = "no-raid"
vol_size =  node.workorder.rfcCi.ciAttributes[:size]
Chef::Log.info("-------------------------------------------------------------")
Chef::Log.info("Volume Size : "+vol_size )
Chef::Log.info("-------------------------------------------------------------")

if node.workorder.rfcCi.ciAttributes[:size] == "-1"
  Chef::Log.info("skipping because size = -1")
  return
end

raid_device = "/dev/md/#{node.workorder.rfcCi.ciName}"
rfc_action = "#{node.workorder.rfcCi.rfcAction}"
no_raid_device = " "

Chef::Log.info("-------------------------------------------------------------")
Chef::Log.info("Raid Device : "+raid_device)
Chef::Log.info("RFC Action  : "+rfc_action)
Chef::Log.info("-------------------------------------------------------------")

node.set["raid_device"] = raid_device
platform_name = node.workorder.box.ciName
logical_name = node.workorder.rfcCi.ciName


cloud_name = node[:workorder][:cloud][:ciName]
token_class = node[:workorder][:services][:compute][cloud_name][:ciClassName].split(".").last.downcase
include_recipe "shared::set_provider"

storage_provider = node.storage_provider_class

if node[:storage_provider_class] =~ /azure/ && !storage.nil?
  include_recipe "azuredatadisk::attach_datadisk"
end

# need ruby block so package resource above run first
ruby_block 'create-iscsi-volume-ruby-block' do
  block do

    Chef::Log.info("------------------------------------------------------")
    Chef::Log.info("Storage: "+storage.inspect.gsub("\n"," "))
    Chef::Log.info("------------------------------------------------------")

    if storage.nil?
      Chef::Log.info("no DependsOn Storage - skipping")
    else
      dev_list = ""
      if node[:storage_provider_class] =~ /azure/
        Chef::Log.info(" the storage device is already attached")
        vols = Array.new
        node[:device_maps].each do |dev_vol|
          vol_id = dev_vol.split(":")[3]
          dev_id = dev_vol.split(":")[4]
          vols.push dev_id
          dev_list += dev_id+" "
        end
      else
        provider = node[:iaas_provider]
        storage_provider = node[:storage_provider]

        instance_id = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["instance_id"]
        Chef::Log.info("instance_id: "+instance_id)
        compute = provider.servers.get(instance_id)

        device_maps = storage['ciAttributes']['device_map'].split(" ")
        vols = Array.new
        dev_list = ""
        i = 0
        device_maps.each do |dev_vol|
          vol_id = dev_vol.split(":")[0]
          dev_id = dev_vol.split(":")[1]
          Chef::Log.info("vol_id: "+vol_id)
          vol = nil
          case token_class
            when /rackspace|ibm/
              vol = storage_provider.volumes.get vol_id
            else
              vol = provider.volumes.get vol_id
          end

          Chef::Log.info("vol: "+ vol.inspect.gsub("\n"," ").gsub("<","").gsub(">","") )
          begin

            case token_class
              when /ibm/
                if vol.attached?
                  Chef::Log.error("attached already, no way to determine device")
                  # mdadm sometime reassembles with _0
                  new_raid_device = `ls -1 #{raid_device}* 2>/dev/null`.chop
                  if new_raid_device.empty?
                    exit 1
                  else
                    raid_device = new_raid_device
                    node.set["raid_device"] = raid_device
                    break
                  end
                end

                # determine new device by watching /dev because ibm (kvm) doesn't attach it to the specified device
                orig_device_list = `ls -1 /dev/vd*`.split("\n")
                compute.attach(vol.id)
                device_list = `ls -1 /dev/vd*`.split("\n")
                retry_count = 0
                max_retry_count = 30
                while orig_device_list.size == device_list.size &&
                    retry_count < max_retry_count do
                  sleep 10
                  retry_count +=1
                  device_list = `ls -1 /dev/vd*`.split("\n")
                end

                if retry_count == max_retry_count
                  Chef::Log.error("max retry count of "+max_retry_count.to_s+" hit ... device list: "+orig_device_list.inspect.gsub("\n"," "))
                  exit 1
                end

                new_dev = nil
                device_list.each do |dev|
                  found = false
                  orig_device_list.each do |d|
                    if dev == d
                      found = true
                    end
                  end
                  if !found
                    new_dev = dev
                    break
                  end
                end

                if new_dev != nil
                  dev_id = new_dev
                  Chef::Log.info "device: "+dev_id
                  node.set["raid_device"] = dev_id
                end

              when /openstack/
                if vol.attachments != nil && vol.attachments.size > 0 &&
                    vol.attachments[0]["serverId"] == instance_id
                  Chef::Log.error("attached already, no way to determine device")
                  # mdadm sometime reassembles with _0
                  new_raid_device = `ls -1 #{raid_device}* 2>/dev/null`.chop
                  if new_raid_device.empty?
                    exit 1
                  else
                    raid_device = new_raid_device
                    break
                  end

                end


                Chef::Log.info("-------------------------------------------")
                Chef::Log.info("dev_id: "+dev_id)
                Chef::Log.info("Instance_id: "+instance_id)
                # determine new device by by watching /dev because openstack (kvm) doesn't attach it to the specified device
                orig_device_list = `ls -1 /dev/vd*`.split("\n")
                vol.attach instance_id, dev_id
                Chef::Log.info("Device Attached ......")
                device_list = `ls -1 /dev/vd*`.split("\n")
                retry_count = 0
                max_retry_count = 12
                while orig_device_list.size == device_list.size &&
                    retry_count < max_retry_count do
                  sleep 15
                  retry_count +=1
                  device_list = `ls -1 /dev/vd*`.split("\n")
                end

                if retry_count == max_retry_count
                  Chef::Log.error("max retry count of "+max_retry_count.to_s+" hit ... device list: "+orig_device_list.inspect.gsub("\n"," "))
                  exit 1
                end

                new_dev = nil
                device_list.each do |dev|
                  found = false
                  orig_device_list.each do |d|
                    if dev == d
                      found = true
                    end
                  end
                  if !found
                    new_dev = dev
                    break
                  end
                end

                if new_dev != nil
                  dev_id = new_dev
                  Chef::Log.info "Assigned Device: "+dev_id
                  Chef::Log.info("-------------------------------------------")
                  no_raid_device = dev_id
                end

              when /rackspace/
                rackspace_dev_id = dev_id.gsub(/\d+/,"")
                is_attached = false
                compute.attachments.each do |a|
                  is_attached = true if a.volume_id = vol.id
                end
                if !is_attached
                  compute.attach_volume vol.id, rackspace_dev_id
                end

                node.set["raid_device"] = rackspace_dev_id

              when /ec2/
                vol.device = dev_id.gsub("xvd","sd")
                vol.server = compute

              when /azure/
                Chef::Log.info(" the storage device is already attached")

            end
          rescue Fog::Compute::AWS::Error=>e
            if e.message =~ /VolumeInUse/
              Chef::Log.info("already added")
            else
              Chef::Log.info(e.inspect)
              exit 1
            end
          end
          vols.push vol_id
          dev_list += dev_id+" "
          i+=1
        end
        newDevicesAttached = dev_list

        # wait until all are attached
        fin = false
        max_retry = 10
        retry_count = 0
        while !fin && retry_count<max_retry do
          fin = true
          vols.each do |vol_id|
            vol = nil
            if token_class =~ /rackspace|ibm/
              vol = storage_provider.volumes.get vol_id
            else
              vol = provider.volumes.get  vol_id
            end

            vol_state = ''
            if token_class =~ /openstack/
              vol_state = vol.status
            else
              vol_state = vol.state
            end
            Chef::Log.info("vol: "+vol_id+" state:"+vol_state)
            if vol_state.downcase != "attached" && vol_state.downcase != "in-use"
              fin = false
              sleep 10
            end
          end
          retry_count +=1

        end

      end

      if node.workorder.rfcCi.ciAttributes.has_key?("mode")
        mode = node.workorder.rfcCi.ciAttributes["mode"]
      end
      level = mode.gsub("raid","")
      msg = ""
      case mode
        when "raid0"
          if vols.size < 2
            msg = "Minimum of 2 storage slices are required for "+mode
          end
        when "raid1"
          if vols.size < 2 || vols.size%2 != 0
            msg = "Minimum of 2 storage slices and storage slice count mod 2 are required for "+mode
          end
        when "raid5"
          if vols.size < 3
            msg = "Minimum of 3 storage slices are required for "+mode
          end
        when "raid10"
          if vols.size < 4 || vols.size%2 != 0
            msg = "Minimum of 4 storage slices and storage slice count mod 2 are required for "+mode
          end
      end
      unless msg.empty?
        puts "***FAULT:FATAL=#{msg}"
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e
      end
      has_created_raid = false
      exec_count = 0
      max_retry = 10

      if vols.size > 1 && mode != 'no-raid'

        cmd = "yes |mdadm --create -l#{level} -n#{vols.size.to_s} --assume-clean --chunk=256 #{raid_device} #{dev_list} 2>&1"
        until ::File.exists?(raid_device) || has_created_raid || exec_count > max_retry do
          Chef::Log.info(raid_device+" being created with: "+cmd)

          out = `#{cmd}`
          exit_code = $?.to_i
          Chef::Log.info("exit_code: "+exit_code.to_s+" out: "+out)
          if exit_code == 0
            has_created_raid = true
            # really always need to readahead 64k?
            # TODO: analyze impact of 64k read-ahead - extra cost to perf
            #`blockdev --setra 65536 /dev/md/#{node.workorder.rfcCi.ciName}`
          else
            exec_count += 1
            sleep 10

            ccmd = "for f in /dev/md*; do mdadm --stop $f; done"
            Chef::Log.info("cleanup bad arrays: "+ccmd)
            Chef::Log.info(`#{ccmd}`)

            ccmd = "mdadm --zero-superblock #{dev_list}"
            Chef::Log.info("cleanup incase re-using: "+ccmd)
            Chef::Log.info(`#{ccmd}`)
          end
        end
        node.set["raid_device"] = raid_device
      else
        Chef::Log.info("No Raid Device ID :" +no_raid_device)
        raid_device = no_raid_device
        node.set["raid_device"] = no_raid_device

      end

    end

  end
end
