sdate = Time.now.strftime("%y%m%d%H%M%S")
log_file = "/tmp/#{node.workorder.actionName}_#{sdate}.txt"
nodetool = "/opt/cassandra/bin/nodetool"
args = ::JSON.parse(node.workorder.arglist)
nodetool_command = args["nodetool_args"].to_s.strip
if nodetool_command.empty?
	nodetool_command = "info"
end
Chef::Log.info("log_file : #{log_file}")
Chef::Log.info("nodetool_command : #{nodetool_command}")
	
Nodetool::Util.validate(node.workorder.createdBy.to_s, nodetool_command)
   
result = `nohup #{nodetool} #{nodetool_command} > #{log_file} &`
if $? != 0
   puts "***FAULT:FATAL=Failed to execute the command"
   e = Exception.new("no backtrace")
   e.set_backtrace("")
   raise e         
end
sleep 10
begin
	status = `ps -eaf | grep '#{log_file}' | grep -v grep`
   cmd = `tail -n 100 #{log_file}`
	Chef::Log.info("#{cmd}")
end while not status.empty?