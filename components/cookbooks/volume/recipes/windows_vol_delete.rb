Chef::Log.info("Windows volume delete recipe")
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

mount_point =  node.workorder.rfcCi.ciAttributes[:mount_point]
reg_ex = /[e-z]|[E-Z]/
if (mount_point.nil? || mount_point.length > 1 || !reg_ex.match(mount_point))
  msg = "Invalid mount point for a windows drive"
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  raise msg
end
set_del_script = "#{Chef::Config[:file_cache_path]}/cookbooks/Volume/files/del_disk.ps1"
Chef::Log.info("Script path: "+set_del_script )
Chef::Log.info("disk letter: "+mount_point)
cmd = "#{set_del_script} \"#{mount_point}\""
Chef::Log.info("cmd:"+cmd)
powershell_script "run del_disk script" do
code cmd
end
