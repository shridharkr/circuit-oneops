def find_bricks(index,replicas,length)
  bricks = Array.new
  for n in 0..(replicas-1)
    brick_id = (index - 1) * replicas + 1 - n * (replicas - 1)
    brick_id = brick_id > 0 ? brick_id : brick_id + length * replicas
    bricks << brick_id
  end
  return bricks
end

def extract_hosts_from_bricks(bricks)
	hosts = Array.new
	bricks.each do |b|
		hosts << b.scan(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/).to_s
	end
	return hosts
end

def execute_command(command, exit_out = true)
	output = `#{command} 2>&1`
	if $?.success?
		Chef::Log.info("#{command} got successful. #{output}")
	else
        exit_with_error "#{command} got failed. #{output}" if exit_out
        Chef::Log.warn("#{command} got failed. #{output}") if !exit_out
	end
end

def exit_with_error(msg)
	puts "***FAULT:FATAL=#{msg}"
	Chef::Application.fatal!(msg)
end

def create_private_key_file()
	exit_with_error "unsupported, missing SecuredBy key in deployment workorder" unless node.workorder.payLoad.has_key? "SecuredBy"
	puuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join
	ssh_key_file = "/tmp/"+puuid
	file ssh_key_file do
		content node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
		mode 0600
	end
	return ssh_key_file
end

def check_for_volume_in_existing_cluster(computes, vol)
	identity_file = create_private_key_file
	ruby_block 'check_volume' do
		block do
			Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
			computes.each do |c|
				ssh_cmd = "ssh -i #{identity_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@#{c.ciAttributes[:private_ip]} "
				vol_cmd = "gluster volume info #{vol}"
				result = shell_out("#{ssh_cmd} \"#{vol_cmd}\"")
				puts "volume result output is: #{result.stdout}"
				break node.set["glusterfs"]["volume_exists"] = "vol #{vol} already exists in cluster pool" if !result.stdout.empty?
			end
		end
	end
end
