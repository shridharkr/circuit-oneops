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
# storage::add
#
# adds block storage ... volume component will attach and create raid device and filesystem 
#

  
# TODO: fix fog/aws devices to remove the /dev/[s|vx]d\d+ limitation
# only 15*8 devices available from sdi1-sdp15 (efgh used for ephemeral)
#

# PGPDBAAS 2613 & 3322 
include_recipe 'shared::set_provider'

provider = node['provider_class']

size_config = node.workorder.rfcCi.ciAttributes["size"]
size_scale = size_config[-1,1]
size = size_config[0..-2].to_i


    Chef::Log.info("----------------------------------------------------------")
    Chef::Log.info("Storage Requested : " + size_config)
    Chef::Log.info("----------------------------------------------------------")

 if size_config == "-1" 
   Chef::Log.info("Skipping Storage Allocation Due to Size is -1")
   return true
  end


slice_count = node.workorder.rfcCi.ciAttributes["slice_count"].to_i
if slice_count.nil?
  slice_count = 1
end


Chef::Log.info("size_scale: "+size_scale)
if size_scale == "T"
  size *= 1024
end
if size < 10
  size = 10
end

if slice_count == 1
  slice_size = size.to_i
 else
 slice_size = (size.to_f / slice_count.to_f).ceil * 2
end 

Chef::Log.info("raid10 - #{slice_count} slices of: #{slice_size}")
          
# Create the dev/vols and store the map to device_map attr ... volume::add will attach them to the compute
dev_list = ""
vols = Array.new

# fog/aws need to use sdf-sdp for ebs devices - e-h used by ephemeral
# find the first unused block device

# openstack+kvm doesn't use explicit device names, just set and order
openstack_dev_set = ['b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v']
azure_dev_set = ['c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v']
block_index = ""
["p","o","n","m","l","k","j","i"].each do |i|      
  dev = "/dev/vxd#{i}0"
  if !::File.exists?(dev)
    block_index = i
    break
  end
end

# lame have to use the sdX device for the call but show up as xvdX (for 11.04)
Array(1..slice_count).each do |i|
  dev = ""
  if node.storage_provider_class =~ /cinder/
    dev = "/dev/vd#{openstack_dev_set[i]}"
  elsif node.storage_provider_class =~ /azure/
    dev = "/dev/sd#{azure_dev_set[i]}"
  else
    dev = "/dev/xvd#{block_index}#{i.to_s}"
  end

  Chef::Log.info("adding dev: #{dev} size: #{slice_size}G")
  volume = nil
  case node.storage_provider_class
  when /cinder/
    
    begin
      vol_name = node["workorder"]["rfcCi"]["ciName"]+"-"+node["workorder"]["rfcCi"]["ciId"].to_s
      volume = node.storage_provider.volumes.new :device => dev, :size => slice_size, :name => vol_name, 
        :description => dev, :display_name => vol_name
      volume.save
    rescue Excon::Errors::RequestEntityTooLarge => e
      puts "***FAULT:FATAL="+JSON.parse(e.response[:body])["overLimit"]["message"]
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    rescue Execption => e
      puts "***FAULT:FATAL="+e.message
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end

  when /rackspace/

    begin
      vol_name = node["workorder"]["rfcCi"]["ciName"]+"-"+node["workorder"]["rfcCi"]["ciId"].to_s          
      volume = node.storage_provider.volumes.new :display_name => vol_name, :size => slice_size.to_i
      volume.save      
    rescue Exception => e
      Chef::Log.info("exception: "+e.inspect)
    end
    
  when /ibm/
    volume = node.storage_provider.volumes.new({
      :name => node.workorder.rfcCi.ciName,
      :format => "RAW",
      :location_id => "41", 
      :size => "60",
      :offering_id => "20035200"
    })        
    volume.save
    # takes ~5min, lets sleep 1min, then try for 10min to wait for Detached state, 
    # because volume::add will error if not in Detached state 
    sleep 60
    max_retry_count = 10
    retry_count = 0
    vol = node.storage_provider.volumes.get volume.id
    while vol.state != "Detached" && retry_count < max_retry_count
      sleep 60
      vol = provider.volumes.get volume.id        
      retry_count += 1
      Chef::Log.info("vol state: "+vol.state)
    end
    
    if retry_count >= max_retry_count
      Chef::Log.error("took more than 10minutes for volume: "+volume.id.to_s+" to be ready and still isn't")
    end

    when /azureblobs/
      if node.workorder.services.has_key?("storage")
        cloud_name = node[:workorder][:cloud][:ciName]
        storage_service = node[:workorder][:services][:storage][cloud_name]
        storage = storage_service["ciAttributes"]
        volume = storage.master_rg+":"+storage.storage_account+":"+(node.workorder.rfcCi.ciId).to_s+":"+slice_size.to_s
      end

    else
    # aws
    avail_zone = ''
    node.storage_provider.describe_availability_zones.body['availabilityZoneInfo'].each do |az|
      puts "az: #{az.inspect}"
      if az['zoneState'] == 'available'
        avail_zone = az['zoneName']
        break
      end
    end
    volume = node.storage_provider.volumes.new :device => dev, :size => slice_size, :availability_zone => avail_zone        
    volume.save
  end

  if node.storage_provider_class =~ /azure/
    Chef::Log.error("Adding #{dev} to the device list")
    vols.push(volume.to_s+":"+dev)
  else
    Chef::Log.info("added "+volume.id.to_s)
    vols.push(volume.id.to_s+":"+dev)
  end
end

puts "***RESULT:device_map="+vols.join(" ")
