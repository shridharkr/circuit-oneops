#
# supports openstack keypair::add
#
require 'fog'

# create if doesn't exist  
# openstack doesnt like '.'
node.set["secgroup_name"] = node.secgroup_name.gsub(".","-")
description = node.workorder.rfcCi.ciAttributes[:description] || node.secgroup_name

conn = node[:iaas_provider]

security_groups = conn.security_groups.all.select { |g| g.name == node.secgroup_name}

if security_groups.empty?
  
  begin
    sg = conn.security_groups.create({:name => node.secgroup_name, :description => description})
    Chef::Log.info("create secgroup: "+sg.inspect)
  rescue Excon::Errors::Error =>e
     msg=""
     case e.response[:body]
     when /\"code\": 400/
      msg = JSON.parse(e.response[:body])['badRequest']['message']
      Chef::Log.error("error response body :: #{msg}")
      puts "***FAULT:FATAL=OpenStack API error: #{msg}"
      raise Excon::Errors::BadRequest, msg
     else
      msg = e.message
      puts "***FAULT:FATAL=OpenStack API error: #{msg}"
      raise Excon::Errors::Error, msg
     end
  rescue Exception => ex
      msg = ex.message
      puts "***FAULT:FATAL= #{msg}"
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e  
  end  
    
else
  sg = security_groups.first
  Chef::Log.info("existing secgroup: #{sg.inspect}") 
end


node.set[:secgroup][:group_id] = sg.id
node.set[:secgroup][:group_name] = sg.name
 
rules = JSON.parse(node.workorder.rfcCi.ciAttributes[:inbound])
rules.each do |rule|
  (min,max,protocol,cidr) = rule.split(" ")
  check = sg.rules.select { |r| r['from_port'].to_i == min.to_i && r['to_port'].to_i == max.to_i && r['ip_protocol'] == protocol && r['ip_range']['cidr'] == cidr }
  if check.empty?
    begin
      Chef::Log.info("rule create: #{rule}")
      sg.create_security_group_rule(min.to_i,max.to_i,protocol,cidr)
    rescue Exception => e
      if e.message =~ /already exists/
        Chef::Log.info("rule exists: #{rule}")
      elsif e.response[:body]  =~ /Invalid|Not enough parameters|not a valid ip network/
        puts "***FAULT:FATAL= Invalid inbound rules specified #{rule}"
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e
      elsif e.response[:body]  =~ /Quota exceeded for resources/
        puts "***FAULT:FATAL= Security group rule quota exceeded"
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e
      else
        msg = e.message
        Chef::Log.fatal(e.inspect)
        puts "***FAULT:FATAL= #{msg}"
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e
      end
    end
  else
    Chef::Log.info("rule exists: #{rule} #{check.inspect}")
  end
end  

#collect existing rules to be deleted which are not in the work-order
del_rules = []
is_del = true
sg.rules.each do |r|
  rules.each do |wo_rule|
    (min,max,protocol,cidr) = wo_rule.split(" ")
    if((r['from_port'].to_i == min.to_i && r['to_port'].to_i == max.to_i && r['ip_protocol'] == protocol && r['ip_range']['cidr'] == cidr)) 
      is_del = false
      break
    end    
  end  
  is_del ? del_rules.push(r) : Chef::Log.info("rule #{r['id']} exists in work-order")
  # reset the boolean flag
  is_del = true
end

#delete rules
del_rules.each do |dr|
  Chef::Log.info("*****deleting rule****** #{dr.inspect}")
  sg.delete_security_group_rule(dr['id'])
end
