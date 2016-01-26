ci = node.workorder.has_key?('rfcCi') ? node.workorder.rfcCi : node.workorder.ci
parent = node.workorder.payLoad.RealizedAs[0]

# mount distributed filesystem
filesys = "glusterfs"
mounttest = `mount |grep #{filesys} |wc -l`

if mounttest.to_i > 0
 Chef::Log.info(" Mount already exists")
 return
end

directory "#{ci.ciAttributes[:mount_point]}" do
  recursive true
  action :create
end

ruby_block 'wait for volume info' do
  block do
    retry_count = 0
    while retry_count < 30
      vol_info = `gluster volume info #{parent[:ciName]}`
      Chef::Log.info("vol_info:: #{vol_info} #{parent[:ciName]}")
      break if((!vol_info.nil? && !vol_info.empty?) && vol_info.match(/(Status:(.*))/)[1].split(':')[1].strip == "Started")

      Chef::Log.warn("gluster volume #{parent[:ciName]} not found or not started, will retry in 10 sec.")
      sleep 10
      retry_count += 1
    end
  end
end

# run it as execute so it fails the recipe when it fails
execute "mount filesystem #{parent[:ciName]} on #{ci.ciAttributes[:mount_point]}" do
  command "mount.glusterfs localhost:/#{parent[:ciName]} #{ci.ciAttributes[:mount_point]}"
end

# run it in ruby block to capture stdout
ruby_block "mounts" do
  block do
    result = `cat /proc/mounts && df -k`
    Chef::Log.info(result)
  end
  action :create
end

mount_point = ci.ciAttributes[:mount_point]
ruby_block "mounts" do
    # clear existing mount_point and add to fstab again to ensure update attributes
    result = `grep -v #{mount_point} /etc/fstab > /tmp/fstab`
    ::File.open("/tmp/fstab","a") do |fstab|
        fstab.puts("localhost:/#{parent[:ciName]} #{mount_point} #{filesys}  defaults,_netdev 0 0")
        Chef::Log.info("adding to fstab : localhost:/#{parent[:ciName]} #{mount_point} glusterfs  defaults,_netdev 0 0")
    end
    `mv /tmp/fstab /etc/fstab`
end
