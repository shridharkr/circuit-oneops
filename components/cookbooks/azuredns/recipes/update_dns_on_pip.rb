require File.expand_path('../../../azure/libraries/public_ip.rb', __FILE__)
require File.expand_path('../../../azure/libraries/utils.rb', __FILE__)
require 'azure_mgmt_network'

::Chef::Recipe.send(:include, AzureNetwork)
::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)
include_recipe 'azure::get_credentials'

cloud_name = node['workorder']['cloud']['ciName']
dns_attributes = node['workorder']['services']['dns'][cloud_name]['ciAttributes']
dns_service = node['workorder']['services']['dns'][cloud_name]

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'
Chef::Log.info("azuredns:update_dns_on_pip.rb - platform-resource-group is: #{node['platform-resource-group']}")

nameutil = Utils::NameUtils.new()
publicip = AzureNetwork::PublicIp.new(node['azureCredentials'], dns_attributes['subscription'])

cloud_name = node[:workorder][:cloud][:ciName]
zone_name = (node[:workorder][:services][:dns][cloud_name][:ciAttributes][:zone])
zone_name = zone_name.split('.').reverse.join('.').partition('.').last.split('.').reverse.join('.')
zone_name = zone_name.gsub(".","-")

if node.app_name == "os"
  public_ip_name = nameutil.get_component_name("publicip",node.workorder.payLoad.DependsOn[0].ciId)
  pip = publicip.get(node['platform-resource-group'], public_ip_name)
  if !node.full_hostname.nil?
    full_hostname = (node.full_hostname).split('.').reverse.join('.').partition('.').last.split('.').reverse.join('.')
    Chef::Log.info("domain name label :" + full_hostname)
    full_hostname = full_hostname.gsub(".","-").downcase
    new_dns_settings = PublicIpAddressDnsSettings.new
    if full_hostname.length >= 61
      new_dns_settings.domain_name_label = full_hostname.slice!(0, 60)
    else
      new_dns_settings.domain_name_label = full_hostname
    end
    pip.properties.dns_settings = new_dns_settings
    publicip.create_update(node['platform-resource-group'], public_ip_name, pip)
    end
end

if node.app_name == "fqdn"

  new_dns_settings = PublicIpAddressDnsSettings.new
  short_name_available = false
  # create a new dns settings object with the new values.
  # only setting the domain_name_label
  # the fqdn automatically gets populated with the name label and "<location>.cloudapp.azure.com"
  if node.workorder.rfcCi.ciAttributes.has_key?('aliases')
    begin
      shortnames = JSON.parse(node.workorder.rfcCi.ciAttributes.aliases)
    end
  end
  if !shortnames.empty?
    if (shortnames[0]).length > 0
      short_name_available = true
      Chef::Log.info('shortnames:'+shortnames[0])
      #whether to add zone or not ?? currently no zone is added.
      new_dns_settings.domain_name_label = (shortnames[0]).downcase # + "-"+zone_name
    else
      Chef::Log.info('short name is empty. User didnt supply shortname ' )
    end
  end
  availability = node.workorder.box.ciAttributes.availability
  if(availability == 'single')
      dependson = node.workorder.payLoad.DependsOn
      dependson.each {
        |depends|
        if depends.ciAttributes.has_key?('instance_name')
          public_ip_name = nameutil.get_component_name("publicip",depends.ciId)
        end
        if short_name_available == false
          if depends.ciAttributes.has_key?('hostname')
            full_hostname =  depends.ciAttributes.hostname
            Chef::Log.info('full_hostname:'+full_hostname)
            full_hostname = (full_hostname).split('.').reverse.join('.').partition('.').last.split('.').reverse.join('.')
            Chef::Log.info("domain name label :" + full_hostname)
            full_hostname = full_hostname.gsub(".","-").downcase
            new_dns_settings = PublicIpAddressDnsSettings.new
            if full_hostname.length >= 61
              new_dns_settings.domain_name_label = full_hostname.slice!(0, 60)
              if new_dns_settings.domain_name_label[59] == '-' #if the last character is - , its invalid domain name label.
                Chef::Log.info("domain name label ends with  - " )
                new_dns_settings.domain_name_label=new_dns_settings.domain_name_label.chomp('-')
              end
            else
              new_dns_settings.domain_name_label = full_hostname
            end
           end
         end
      }
      if new_dns_settings.domain_name_label != nil
        Chef::Log.info('setting domain label: ' + new_dns_settings.domain_name_label)
        if public_ip_name != nil
          pip = publicip.get(node['platform-resource-group'], public_ip_name)
          pip.properties.dns_settings = new_dns_settings
            # update the public ip with the new dns settings
          publicip.create_update(node['platform-resource-group'], public_ip_name, pip)
       end
    end
  elsif availability == 'redundant'
    Chef::Log.info('environment:'+availability)
    if node.workorder.payLoad.has_key?('lb')
      lb_list = node.workorder.payLoad.lb
      lb_list.each {
        |lb|
        if lb.has_key?('ciId')
          ci_id = lb.ciId
        end
      public_ip_name = nameutil.get_component_name("lb_publicip",ci_id)
      Chef::Log.info("lb_publicip name :"+public_ip_name )
      if short_name_available == false
        Chef::Log.info("shortname is unavailable")
        instance = (node.workorder.payLoad.DependsOn[0].ciId.to_s)
        cloud_id = ((node.workorder.rfcCi.ciName).split("-",2)).last
        subdomain = node.workorder.payLoad.Environment[0]["ciAttributes"]["subdomain"]
        nameutil = Utils::NameUtils.new()
        new_dns_settings.domain_name_label = nameutil.get_dns_domain_label("lb",cloud_id,instance,subdomain) +"-"+ zone_name
        if (new_dns_settings.domain_name_label).length >= 61
          new_dns_settings.domain_name_label = new_dns_settings.domain_name_label.slice!(0,60)
          if new_dns_settings.domain_name_label[59] == '-' #if the last character is - , its invalid domain name label.
            Chef::Log.info("domain name label ends with  - " )
            new_dns_settings.domain_name_label=new_dns_settings.domain_name_label.chomp('-')
          end
        end
      end
      if new_dns_settings.domain_name_label != nil
        Chef::Log.info('domain label: ' + new_dns_settings.domain_name_label)
        if public_ip_name != nil
            Chef::Log.info('searching public_ip_name:'+public_ip_name+'in'+node['platform-resource-group'])
            ip_found = publicip.check_existence_publicip(node['platform-resource-group'], public_ip_name)
            if ip_found == true
              Chef::Log.info('found !')
              pip = publicip.get(node['platform-resource-group'], public_ip_name)
            else
              next
            end
          pip.properties.dns_settings = new_dns_settings
          Chef::Log.info('updating domain label: ' + new_dns_settings.domain_name_label)
            # update the public ip with the new dns settings
          publicip.create_update(node['platform-resource-group'], public_ip_name, pip)
       end
      end
     }
    end
    full_hostname = nil
  end



end

if node.app_name == "lb"
  instance = (node.workorder.rfcCi.ciId.to_s)
  cloud_id = ((node.workorder.rfcCi.ciName).split("-",2)).last
  subdomain = node.workorder.payLoad.Environment[0]["ciAttributes"]["subdomain"]
  nameutil = Utils::NameUtils.new()
  node.set["domain_name_label"] = nameutil.get_dns_domain_label("lb",cloud_id,instance,subdomain) +"-"+ zone_name
  if node.domain_name_label.length >= 61
    node.set["domain_name_label"] = (node.domain_name_label).slice!(0,60)
  end
  Chef::Log.info('domain label is: ' + node.domain_name_label)
  return true
end
