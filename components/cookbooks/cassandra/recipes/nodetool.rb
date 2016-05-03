#check if nodetool command is already running
command = "ps -eaf | grep NodeTool | grep -v grep | wc -l"
cmd = `#{command}`
if cmd.to_i > 0
  puts "***FAULT:FATAL=notetool command is already in progress"
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end
sdate = Time.now.strftime("%y%m%d%H%M%S")
log_file = "/tmp/nodetool_#{sdate}.txt"
args = ::JSON.parse(node.workorder.arglist)
nodetool_arguments = args["nodetool_args"]

#submit nodetool command in background
`nohup /opt/cassandra/bin/nodetool #{nodetool_arguments} > #{log_file} &`

#monitor the nodetool log
running = true
while running
  sleep 10
  cmd = `tail -n 100 #{log_file}`
  puts cmd
  cmd = `#{command}`
  if cmd.to_i == 0
    running = false
  end
end