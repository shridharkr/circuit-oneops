sdate = Time.now.strftime("%y%m%d%H%M%S")
log_file = "/tmp/#{node.workorder.actionName}_#{sdate}.txt"
nodetool = "/opt/cassandra/bin/nodetool"
args = ::JSON.parse(node.workorder.arglist)
nodetool_command = args["nodetool_args"].to_s.strip
if nodetool_command.empty?
	nodetool_command = "status"
end
Chef::Log.info("log_file : #{log_file}")
Chef::Log.info("nodetool_command : #{nodetool_command}")
	
Nodetool::Util.validate(node.workorder.createdBy.to_s, nodetool_command)
output = `#{nodetool} #{nodetool_command} > #{log_file} & echo $!`
rows = output.split("\n")
result = ""
rows.each do |row|
   Chef::Log.info("row: #{row}")
   parts = row.split(" ")
	next unless parts.size == 1
	result = parts[0]
end
if $? != 0
   puts "***FAULT:FATAL=Failed to execute the command"
   e = Exception.new("no backtrace")
   e.set_backtrace("")
   raise e         
end
sleep 5
begin
   cmd = `tail -n 100 #{log_file}`
 	Chef::Log.info("#{cmd}")
   `ps -p #{result} 2>&1`
    if $? != 0 
 		break
 	end
end while true