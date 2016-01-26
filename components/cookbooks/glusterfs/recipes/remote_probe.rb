ci = node.workorder.rfcCi
compute_index = ci[:ciName].split('-').last.to_i
cloud_index = ci[:ciName].split('-').reverse[1].to_i
computes = node.workorder.payLoad.RequiresComputes
local_ip = node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]

unless node.workorder.payLoad.has_key? "SecuredBy"
  Chef::Log.error("unsupported, missing SecuredBy")
  return false
end

# tmp file to store private key
puuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join
ssh_key_file = "/tmp/"+puuid

file ssh_key_file do
  content node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
  mode 0600
end

ssh_key_file = ssh_key_file

ruby_block 'remote peer probe' do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    computes.each do |c|
    
      ssh_cmd = "ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@#{c.ciAttributes[:private_ip]} "
      probe_cmd = "gluster peer probe #{local_ip}"
     # puts "final cmd : #{ssh_cmd} \"#{probe_cmd}\""
      peer_probe = shell_out("#{ssh_cmd} \"#{probe_cmd}\"")
      puts peer_probe.stdout
     # break if (peer_probe.stdout.include? "peer probe: success") && !(peer_probe.stdout.include? "already in peer list") && !(peer_probe.stdout.include? "Probe on localhost not needed")
    
    end
  end
end
