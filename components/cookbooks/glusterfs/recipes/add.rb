
environment = node.workorder.payLoad.Environment[0][:ciAttributes][:availability]

if environment=="single"
  Chef::Log.error("******** exiting because glusterfs setup works in redundant environment only ********")
  return
end

ci = node.workorder.rfcCi
parent = node.workorder.payLoad.RealizedAs[0]
replicas = ci.ciAttributes[:replicas].to_i
local_compute_index = ci[:ciName].split('-').last.to_i
local_cloud_index = ci[:ciName].split('-').reverse[1].to_i
computes = node.workorder.payLoad.RequiresComputes
compute_cinames=Array.new

computes.each do |c|
  compute_cinames.push("#{c.ciName}")
end

last_compute=compute_cinames.max

volstore_prefix = "#{ci.ciAttributes[:store]}/#{parent[:ciName]}"
Chef::Log.info("Distributed filesystem on #{computes.size.to_s} computes with #{replicas.to_s} data replicas")

cloud_name = node[:workorder][:cloud][:ciName]
  if node[:workorder][:services].has_key? "mirror"
    mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
  else
    msg = "Cloud Mirror Service has not been defined"
    Chef::Log.error(msg)
    puts "***FAULT:FATAL= #{msg}"
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e
  end

glusterfs_source = mirrors['glusterfs']
if glusterfs_source.nil?
  msg = "glusterfs source repository has not beed defined in cloud mirror service"
  Chef::Log.error(msg)
  puts "***FAULT:FATAL= #{msg}"
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
else
  Chef::Log.info("glusterfs source repository has been defined in cloud mirror service #{glusterfs_source}")
end

template "/etc/yum.repos.d/glusterfs.repo" do
  source "glusterfs.repo.erb"
  owner "root"
  group "root"
  mode "0644"
  variables({
    :glusterfs_source => glusterfs_source,
    :glusterfs_version => node.glusterfs.version
  })
end

# purge libs in case cloud-init installed the wrong version
['glusterfs-libs'].each do |p|
  package "#{p}" do
    action :remove
  end
end

['glusterfs-client','glusterfs-server','glusterfs-common','glusterfs-devel'].each do |p|
  package "#{p}"
end

service "glusterd" do
  supports :restart => true, :status => true
  action [ :enable, :start ]
end

# staircase brick layout optimized for minimum migrations when computes are added
local_bricks = find_bricks(local_compute_index,replicas,computes.length)

local_bricks.each do |b|
  directory "#{volstore_prefix}/#{b}" do
    recursive true
    action :create
  end
end

if node.workorder.rfcCi.rfcAction == 'replace'
  include_recipe "glusterfs::remote_probe"
end

# initialize volume on last compute node
if last_compute == "compute-#{local_cloud_index}-#{local_compute_index}"
  Chef::Log.info("Initializing gluster volume on last compute")

  computes.each do |c|
    ruby_block "adding gluster peer" do
      block do
        retry_count = 1
        while retry_count < 4
          result = `gluster peer probe #{c.ciAttributes[:private_ip]} 2>&1`
          if $?.success?
            Chef::Log.info("gluster peer probe #{c.ciAttributes[:private_ip]} is successful. #{result}")
            break
          else
            Chef::Log.info("gluster peer probe #{c.ciAttributes[:private_ip]} is failed. #{result}. Will sleep and re-try again. Maximum try count is set as 3.")
            Chef::Log.info("sleeping 60 seconds. Re-try number is #{retry_count}")
            sleep 60
          end
          Chef::Application.fatal!("gluster peer probe #{c.ciAttributes[:private_ip]} is failed. #{result}") if retry_count == 3
          retry_count += 1
        end
      end
      action :create
    end
  end

  ruby_block "peer status" do
    block do
      result = `gluster peer status 2>&1`
      Chef::Log.info("peer status result is: #{result}")
    end
    action :create
  end

  bricks = {}
  computes.each do |c|
    compute_bricks = find_bricks(c[:ciName].split('-').last.to_i,replicas,computes.length)
    Chef::Log.info("Bricks for #{c[:ciName]} (#{c.ciAttributes[:private_ip]}) #{compute_bricks.inspect}")
    compute_bricks.each do |b|
      bricks["#{c.ciName}"] = "#{c.ciAttributes[:private_ip]}:#{volstore_prefix}/#{b}"
    end
  end

  replicas_arg = replicas > 1 ? "replica #{replicas}" : ""
  bricks_arg = bricks.sort.map{|b| b[1]}.join(' ')
  ruby_block "creating gluster volume" do
    block do
      result = `yes y | gluster volume create #{parent[:ciName]} #{replicas_arg} #{bricks_arg} force 2>&1`
      if $?.success?
        Chef::Log.info("gluster volume create #{parent[:ciName]} #{replicas_arg} #{bricks_arg} force is successful. #{result}")
        break
      else
        Chef::Application.fatal!("gluster volume create #{parent[:ciName]} #{replicas_arg} #{bricks_arg} force is failed. #{result}")
      end
    end
    not_if "gluster volume info #{parent[:ciName]}"
    action :create
  end

  ruby_block "volume start #{parent[:ciName]}" do
    block do
      sleep 5
      result = `gluster volume start #{parent[:ciName]} 2>&1`
      Chef::Log.info("volume start result is: #{result}")
    end
    only_if "gluster volume info #{parent[:ciName]}"
    action :create
  end

  ruby_block "volume info #{parent[:ciName]}" do
    block do
      result = `gluster volume info #{parent[:ciName]} 2>&1`
      Chef::Log.info("volume info result is: #{result}")
    end
    action :create
  end

  # run info again to check the return code and fail if not 0
  execute "gluster volume info #{parent[:ciName]}"
end

include_recipe "glusterfs::mount"
