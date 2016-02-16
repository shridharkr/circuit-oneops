nodes = node.workorder.payLoad.ManagedVia
port = 6379

#if node.platform =~ /redhat|centos/
redisio_bin = "/usr/local/bin"
redisio_trib = "#{redisio_bin}/redis-trib.rb"
#end

instances = []
tinstances = []
sinstances = []

# Setup initial Redis cluster node
nodes.each do |compute|
  ip = compute[:ciAttributes][:private_ip]
  puts ip
  instances = ["#{ip}:#{port}"]
  puts instances[0]
  tinstances.push(instances)
  sinstances = tinstances.join(" ")
  puts sinstances
end

#Answer file
File.open('/tmp/answer.txt', 'w') do |f2|
     f2.puts "yes\n"
end

#execute "#{redisio_trib} create --replicas 1 #{sinstances} < /tmp/answer.txt"  do
if File.exist?("#{redisio_trib}")
		execute "create cluster" do
        	command "#{redisio_trib} create --replicas 1 #{sinstances} < /tmp/answer.txt"
		end
	else
		print "#{sinstances}"
end

#dns_record used for fqdn
dns_record = ""
nodes.each do |n|
  if dns_record == ''
    dns_record = n[:ciAttributes][:dns_record]
  else
    dns_record += ',' + n[:ciAttributes][:dns_record]
  end
end

execute "Remove Temp file" do
    cwd "/tmp"
    command "rm /tmp/answer.txt"
end

puts "***RESULT:dns_record=#{dns_record}"
