ci = node.workorder.rfcCi
compute_index = ci[:ciName].split('-').last.to_i
cloud_index = ci[:ciName].split('-').reverse[1].to_i
computes = node.workorder.payLoad.RequiresComputes
local_ip = node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]

exit_with_error "unsupported, missing SecuredBy key in deployment workorder" unless node.workorder.payLoad.has_key? "SecuredBy"

identity_file = create_private_key_file

ruby_block 'remote peer probe' do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    computes.each do |c|
      ssh_cmd = "ssh -i #{identity_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@#{c.ciAttributes[:private_ip]} "
      probe_cmd = "gluster peer probe #{local_ip}"
      result = shell_out("#{ssh_cmd} \"#{probe_cmd}\"")
      puts "probe result output is: #{result.stdout}"
    end
  end
end
