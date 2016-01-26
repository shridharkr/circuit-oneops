#
# gslb_service provider
#
def delete_gslb_service_by_name(gslb_service_name)

  conn = @new_resource.connection

  resp_obj = JSON.parse(conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/gslbservice/#{gslb_service_name}").body)        

  if resp_obj["message"] !~ /The GSLB service does not exist/
    
    Chef::Log.info( "gslb_service_name: #{gslb_service_name}")
    
    resp_obj = JSON.parse(conn.request(
      :method=>:delete, 
      :path=>"/nitro/v1/config/gslbservice/#{gslb_service_name}").body)
    
    if resp_obj["errorcode"] != 0
      if resp_obj["errorcode"] == 344
        Chef::Log.info("already deleted.")          
      else      
        Chef::Log.error( "delete #{gslb_service_name} resp: #{resp_obj.inspect}")    
        exit 1      
      end
  
    else
      Chef::Log.info( "delete #{gslb_service_name} resp: #{resp_obj.inspect}")
    end
    
    
  else 
    Chef::Log.info( "#{gslb_service_name} by platofrm already deleted.")
  end  
  
end


def delete_gslb_service()
  # backwards compat
  delete_gslb_service_by_name(get_gslb_service_name)
  delete_gslb_service_by_name(get_gslb_service_name_by_platform)  
end


def get_gslb_service_name
  env_name = node.workorder.payLoad.Environment[0]["ciName"]
  platform_name = node.workorder.box.ciName
  cloud_name = node.workorder.cloud.ciName
  ci = node.workorder.payLoad.DependsOn[0]
  asmb_name = node.workorder.payLoad.Assembly[0]["ciName"]
  gdns_cloud_service = node.workorder.services["gdns"][cloud_name]
  dc_name = gdns_cloud_service[:ciAttributes][:gslb_site_dns_id]
  
  return [env_name, platform_name, asmb_name, dc_name, ci["ciId"].to_s, "gslbsrvc"].join("-")
end

def get_gslb_service_name_by_platform
  env_name = node.workorder.payLoad.Environment[0]["ciName"]
  platform_name = node.workorder.box.ciName
  cloud_name = node.workorder.cloud.ciName
  ci = node.workorder.box
  asmb_name = node.workorder.payLoad.Assembly[0]["ciName"]
  gdns_cloud_service = node.workorder.services["gdns"][cloud_name]
  dc_name = gdns_cloud_service[:ciAttributes][:gslb_site_dns_id]
  
  return [env_name, platform_name, asmb_name, dc_name, ci["ciId"].to_s, "gslbsrvc"].join("-")
end

def create_gslb_service
  gslb_service_name = get_gslb_service_name
  conn = @new_resource.connection
  
  Chef::Log.info("gslb_service_name: #{gslb_service_name}")

  # check for gslb_service
  resp_obj = JSON.parse(conn.request(
    :method => :get, 
    :path => "/nitro/v1/config/gslbservice/#{gslb_service_name}").body)
  
  # backwards compat
  if resp_obj["message"] =~ /The GSLB service does not exist/
  
    gslb_service_name = get_gslb_service_name_by_platform
    Chef::Log.info("platform gslb_service_name: #{gslb_service_name}")
  
    resp_obj = JSON.parse(conn.request(
      :method=>:get, 
      :path=>"/nitro/v1/config/gslbservice/#{gslb_service_name}").body)  
      
  end

  gslb_service = {
    :servicename => gslb_service_name,
    :servername => @new_resource.servername,
    :port =>  @new_resource.port,
    :servicetype => @new_resource.servicetype,
    :sitename => @new_resource.sitename,
    :state => @new_resource.state
  }

  lb = node.workorder.payLoad.lb.first
  if lb['ciAttributes']['stickiness'] == 'true'
    gslb_service[:sitepersistence] = "ConnectionProxy"
  end
  
  if resp_obj["message"] =~ /The GSLB service does not exist/    
  
    Chef::Log.info( "gslb_service_name: #{gslb_service_name}")
        
    puts "gslb_service: #{gslb_service.inspect}"
    req = 'object= { "gslbservice":'+JSON.dump(gslb_service)+'}'
        
    resp_obj = JSON.parse(conn.request(
      :method=>:post, 
      :path=>"/nitro/v1/config/gslbservice", 
      :body => URI::encode(req)).body)
    
    if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 304
      Chef::Log.error( "post #{gslb_service_name} resp: #{resp_obj.inspect}")
      exit 1
    else
      if resp_obj["errorcode"] == 304
        Chef::Log.info( "local lbvserver: #{resp_obj.inspect}")
        return
      end
      Chef::Log.info("post #{gslb_service_name} resp: #{resp_obj.inspect}")
    end   
    
  else 

    Chef::Log.info("gslb service exists: #{resp_obj.inspect}")
    existing_service = resp_obj["gslbservice"][0]
    
    gslb_service_ip = existing_service["ipaddress"]

    if @new_resource.serverip != gslb_service_ip || 
      lb['ciAttributes']['stickiness'] == 'true' ||
       existing_service["state"] !=  @new_resource.state ||
       existing_service["port"].to_i != @new_resource.port.to_i
      
      # put / update doesn't support state or ip change, need to delete then add
      delete_gslb_service
      sleep 2
      create_gslb_service
    end
      
       
  end
  
  # binding from gslbvserver to gslbservice
  resp_obj = JSON.parse(conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/gslbvserver_gslbservice_binding/#{@new_resource.gslb_vserver}").body)        
    
  if resp_obj.has_key?("gslbvserver_gslbservice_binding")
    bindings = resp_obj["gslbvserver_gslbservice_binding"]
    bindings.each do |binding|
     if binding["gslbboundsvctype"] != @new_resource.servicetype &&
        binding["servicetype"] != @new_resource.servicetype
        
        servicename = binding["servicename"]
        resp_obj = JSON.parse(conn.request(
              :method=>:delete,
              :path=>"/nitro/v1/config/gslbservice/#{servicename}").body)

        Chef::Log.info( "cleanup bind #{servicename} resp: #{resp_obj.inspect} due to: #{binding["servicetype"]} != #{@new_resource.servicetype}")
        Chef::Log.info( "binding: #{binding.inspect}")
        Chef::Log.info( "conn: #{conn.inspect}")

        if resp_obj["errorcode"] != 0
          Chef::Log.error( "cleanup bind #{servicename} resp: #{resp_obj.inspect}")
          exit 1
        end

      end
    end
  end

 
  bindings = Array.new
  if !resp_obj["gslbvserver_gslbservice_binding"].nil?
     bindings = resp_obj["gslbvserver_gslbservice_binding"].select{|v| v["servicename"] == gslb_service_name }
  end

  if bindings.size == 0  
    binding = { :name => @new_resource.gslb_vserver, :servicename => gslb_service_name }    
  
    req = 'object= { "gslbvserver_gslbservice_binding" : '+JSON.dump(binding)+ '}'
      
    resp_obj = JSON.parse(conn.request(
      :method=>:post, 
      :path=>"/nitro/v1/config/gslbvserver_gslbservice_binding/", 
      :body => URI::encode(req)).body)
  
    if resp_obj["errorcode"] != 0
      Chef::Log.error( "post bind #{gslb_service_name} resp: #{resp_obj.inspect}")
      exit 1      
    else
      Chef::Log.info( "post bind #{gslb_service_name} resp: #{resp_obj.inspect}")
    end
    
  else 
    Chef::Log.info( "bind exists: #{bindings.inspect}")
  end        
  

end


action :create do
   create_gslb_service
end

action :delete do
  delete_gslb_service
end

def load_current_resource
  @current_resource = Chef::Resource::NetscalerGslbService.new(@new_resource.name)
end


