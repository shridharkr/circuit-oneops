include_recipe "compute::ssh_cmd_for_remote"


ruby_block 'format disk' do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)

    check_device_availabilty_cmd = "sudo lsblk /dev/sdc"
    device_status = shell_out("#{node.ssh_cmd} \"#{check_device_availabilty_cmd}\"")
    begin
      device_status.error!
      Chef::Log.info("device /dev/sdc OK")
    rescue Exception => e
      Chef::Log.error("Device /dev/sdc not found")
      puts "***FAULT:FATAL=Device /dev/sdc not found"
      ex = Exception.new('no backtrace')
      ex.set_backtrace('')
      raise ex
    end

    #create_partition_cmd = "echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdc"


    make_fs_cmd = "echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdc1; echo "y"|sudo mkfs -t ext4 /dev/sdc1"
    fs_status = shell_out("#{node.ssh_cmd} \"#{make_fs_cmd}\"")

    begin
      fs_status.error!
      Chef::Log.info("filesystem created on /dev/sdc1 OK")
    rescue Exception => e
      Chef::Log.error("Error in creating filesystem on the device /dev/sdc1")
      puts "***FAULT:FATAL=Error in creating filesystem on the device /dev/sdc1"
      ex = Exception.new('no backtrace')
      ex.set_backtrace('')
      raise ex
    end

    mount_cmd = "sudo mkdir /data1;sudo mount /dev/sdc1 /data1"
    mount_status = shell_out("#{node.ssh_cmd} \"#{mount_cmd}\"")
    begin
      fs_status.error!
      Chef::Log.info("filesystem mounted on /dev/sdc1 OK")
    rescue Exception => e
      Chef::Log.error("Error in mounting /dev/sdc1 to mount point /data1 for the data disk"
    end
  end
end
