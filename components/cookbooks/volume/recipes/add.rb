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

is_single = true
if node.workorder.box[:ciAttributes][:availability] != "single"
  is_single = false
end

cloud_name = node[:workorder][:cloud][:ciName]
token_class = node[:workorder][:services][:compute][cloud_name][:ciClassName].split(".").last.downcase
include_recipe "shared::set_provider"


# need ruby block so package resource above run first


ruby_block 'create-iscsi-volume-ruby-block' do
  block do

    Chef::Log.info("------------------------------------------------------")
    Chef::Log.info("Storage: "+storage.inspect.gsub("\n"," "))
    Chef::Log.info("------------------------------------------------------")


    if storage.nil?

       Chef::Log.info("no DependsOn Storage - skipping")

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

      mode = "raid10"
      if node.workorder.rfcCi.ciAttributes.has_key?("mode")
        mode = node.workorder.rfcCi.ciAttributes["mode"]
      end
      level = mode.gsub("raid","")
      has_created_raid = false
      exec_count = 0

      if vols.size > 1

       cmd = "mdadm --create -l#{level} -n#{vols.size.to_s} --assume-clean --chunk=256 #{raid_device} #{dev_list} 2>&1"
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
     else
      Chef::Log.info ("No Raid Device ID :" +no_raid_device)
      raid_device = no_raid_device
      node.set["raid_device"] = no_raid_device

     end

    end

  end
end


### filesystem - check for new attr and exit for backwards compat
_mount_point = nil
_device = nil
_fstype = nil
_options = nil
attrs = node.workorder.rfcCi.ciAttributes
if attrs.has_key?("mount_point")
  Chef::Log.info("using filesystem-in-volume logic")
  _mount_point = attrs["mount_point"]
  _device = attrs["device"]
  _options = attrs["options"]
  _fstype = attrs["fstype"]
end

if node[:platform_family] == "rhel" && node[:platform_version].to_i >= 7
 Chef::Log.info("starting the logical volume manager.")
 service 'lvm2-lvmetad' do
   action [:enable, :start]
   provider Chef::Provider::Service::Systemd
 end
end

ruby_block 'create-ephemeral-volume-ruby-block' do
  # only create ephemeral if doesn't depend_on storage
  not_if { _fstype == "tmpfs" || !storage.nil? }
  block do
    #get rid of /mnt if provider added it
    inital_mountpoint = "/mnt"
      `umount #{inital_mountpoint}`
      `egrep -v "\/mnt" /etc/fstab > /tmp/fstab`
      `mv -f /tmp/fstab /etc/fstab`


    devices = Array.new
    # c,d are used on aws m1.medium - j,k are set on aws rhel 6.3 L
    device_set = ["b","c","d","e","f","g","h","i","j","k"]

    # aws
    device_prefix = "/dev/xvd"
    case token_class
    when /azure/
       device_prefix = "/dev/sd"
       device_set = ["c"] # Using first datadisk attached to the compute. sdb cannot be use, bcoz it is wiped off on deallocate action(might happen during maintenance)
       Chef::Log.info("using azure sdc")

    when /openstack/
       device_prefix = "/dev/vd"
       device_set = ["b"]
       Chef::Log.info("using openstack vdb")
    end

    df_out = `df -k`.to_s
    device_set.each do |ephemeralIndex|
      ephemeralDevice = device_prefix+ephemeralIndex
      if ::File.exists?(ephemeralDevice) && df_out !~ /#{ephemeralDevice}/
        # remove partitions - azure and rackspace add them
        `parted #{ephemeralDevice} rm 1`
         Chef::Log.info("removing partition #{ephemeralDevice}")
         devices.push(ephemeralDevice)
      end
    end

    total_size = 0
    device_list = ""
    existing_dev = `pvdisplay -s`
    devices.each do |device|
      dev_short = device.split("/").last
      if existing_dev !~ /#{dev_short}/
          Chef::Log.info("pvcreate #{device} ..."+`pvcreate -f #{device}`)
          device_list += device+" "
      end
    end

    if device_list != ""
      Chef::Log.info("vgcreate #{platform_name}-eph #{device_list} ..."+`vgcreate -f #{platform_name}-eph #{device_list}`)
    else
      Chef::Log.info("no ephemerals.")
    end

    size = node.workorder.rfcCi.ciAttributes["size"]
    l_switch = "-L"
    if size =~ /%/
      l_switch = "-l"
    end

    `vgdisplay #{platform_name}-eph`
    if $?.to_i == 0

      `lvdisplay /dev/#{platform_name}-eph/#{logical_name}`
      if $?.to_i != 0
        # pipe yes to agree to clear filesystem signature
        cmd = "yes | lvcreate #{l_switch} #{size} -n #{logical_name} #{platform_name}-eph"
        Chef::Log.info("running: #{cmd} ..."+`#{cmd}`)
        if $? != 0
          Chef::Log.error("error in lvcreate")
          exit 1
        end
      end

    end

  end
end

ruby_block 'create-storage-ebs-volume' do
  only_if { storage != nil && token_class !~ /virtualbox|vagrant/}
  block do

   raid_device = node.raid_device

    devices = Array.new
    if ::File.exists?(raid_device)
      Chef::Log.info(raid_device+" exists.")
      devices.push(raid_device)
    else
      Chef::Log.info(raid_device+" missing.")
      exit 1
    end

    total_size = 0
    device_list = ""
    existing_dev = `pvdisplay -s`
    devices.each do |device|
      dev_short = device.split("/").last
      if existing_dev !~ /#{dev_short}/
          Chef::Log.info("pvcreate #{device} ..."+`pvcreate #{device}`)
          device_list += device+" "
      end
    end

    if device_list != ""
      # yes | and -ff needed sometimes
      Chef::Log.info("vgcreate #{platform_name} #{device_list} ..."+`yes | vgcreate -ff #{platform_name} #{device_list}`)
    else
      Chef::Log.info("Volume Group Exists Already")
    end


    size = node.workorder.rfcCi.ciAttributes["size"]
    l_switch = "-L"
    if size =~ /%/
      l_switch = "-l"
    end

    `lvdisplay /dev/#{platform_name}/#{logical_name}`
    if $?.to_i != 0
      cmd = "lvcreate #{l_switch} #{size} -n #{logical_name} #{platform_name}"
      Chef::Log.info("running: #{cmd} ..."+`#{cmd}`)
      if $? != 0
        Chef::Log.error("error in lvcreate")
        exit 1
      end
    end

    `vgchange -ay #{platform_name}`
      if $? != 0
        Chef::Log.error("Error in vgchange")
        exit 1
      end

  end
end


if token_class =~ /ibm/
  _fstype = "ext3"
end

package "xfsprogs" do
  only_if { _fstype == "xfs" }
end

ruby_block 'filesystem' do
  not_if { _mount_point == nil || _fstype == "tmpfs" }
  block do

    block_dev = node.workorder.rfcCi
    _device = "/dev/#{platform_name}/#{block_dev['ciName']}"

    # if ebs/storage exists then use it, else use the -eph ephemeral volume
    if ! ::File.exists?(_device)
      _device = "/dev/#{platform_name}-eph/#{block_dev['ciName']}"

      if ! ::File.exists?(_device)
        # micro,tiny and rackspace don't have ephemeral
        Chef::Log.info("_device #{_device} don't exists")
        next
      end
    end

    if _options == nil || _options.empty?
      _options = "defaults"
    end

    case _fstype
    when 'nfs', 'nfs4'
      include_recipe "volume::nfs"
    end

    Chef::Log.info("filesystem type: "+_fstype+" device: "+_device +" mount_point: "+_mount_point)
    # result attr updates cms
    Chef::Log.info("***RESULT:device="+_device)

    if _device =~ /-eph\//

      `mountpoint -q #{_mount_point}`
      if $?.to_i == 0
        Chef::Log.info("device #{_mount_point} already mounted.")
        next
      end

      type = (`file -sL #{_device}`).chop.split(" ")[1]

    Chef::Log.info("-------------------------")
    Chef::Log.info("Type : = "+type )
    Chef::Log.info("-------------------------")

     if type == "data"
       if node[:platform_family] == "rhel" && (node[:platform_version]).to_i >= 7
         cmd = "mkfs -t #{_fstype} #{_device}" # -f switch not valid in latest mkfs
       else
         cmd = "mkfs -t #{_fstype} -f #{_device}"
       end

        Chef::Log.info(cmd+" ... "+`#{cmd}`)
      end

      # in-line because of the ruby_block doesn't allow updated _device value passed to mount resource
      `mkdir -p #{_mount_point}`
      cmd = "mount -t #{_fstype} -o #{_options} #{_device} #{_mount_point}"
      result = `#{cmd}`
      if result.to_i != 0
         Chef::Log.error("mount error: #{result.to_s}")
      end

    end
      if is_single || _device =~ /-eph\//
      	# clear and add to fstab again to make sure has current attrs on update
      	result = `grep -v #{_device} /etc/fstab > /tmp/fstab`
	  ::File.open("/tmp/fstab","a") do |fstab|
          fstab.puts("#{_device} #{_mount_point} #{_fstype} #{_options} 1 1")
          Chef::Log.info("adding to fstab #{_device} #{_mount_point} #{_fstype} #{_options} 1 1")
	end
        `mv /tmp/fstab /etc/fstab`
      else
       Chef::Log.info("non-single platform w/ block storage - letting crm / resouce mgmt mount")
      end

      	if token_class =~ /azure/
            `sudo mkdir /opt/oneops/workorder`
            `sudo chmod 777 /opt/oneops/workorder`
	end

   end
end

ruby_block 'ramdisk tmpfs' do
  only_if { _fstype == "tmpfs" }
  block do

    # Unmount existing mount for the same mount_point
    `mount | grep #{_mount_point}`
    if $?.to_i == 0
        Chef::Log.info("device #{_device} for mount-point #{_mount_point} already mounted.Will unmount it.")
        umount_res = `umount #{_mount_point}`
        if umount_res.to_i != 0
         Chef::Log.error("umount error: #{umount_res.to_s}")
        end
    end

    _size = node.workorder.rfcCi.ciAttributes["size"]
    if _options == nil || _options.empty?
      _options = "defaults"
    end

    Chef::Log.info("mounting ramdisk :: filetype:#{_fstype} dir:#{_mount_point} device:#{_device} size:#{_size} options:#{_options}")

    # Make directory if not existing
    `mkdir -p #{_mount_point}`

    cmd = "mount -t #{_fstype} -o size=#{_size} #{_fstype} #{_mount_point}"
    result = `#{cmd}`
    if result.to_i != 0
         Chef::Log.error("mount error: #{result.to_s}")
    end

    # clear existing mount_point and add to fstab again to ensure update attributes and to persist the ramdisk across reboots
      result = `grep -v #{_mount_point} /etc/fstab > /tmp/fstab`
      ::File.open("/tmp/fstab","a") do |fstab|
          fstab.puts("#{_device} #{_mount_point} #{_fstype} #{_options},size=#{_size}")
          Chef::Log.info("adding to fstab #{_device} #{_mount_point} #{_fstype} #{_options}")
      end
      `mv /tmp/fstab /etc/fstab`
  end
end
