require 'time'
require 'uri'
require 'openssl'
require 'base64'
require 'net/https'
require 'net/http'
require 'rest_client'
require 'azure_mgmt_compute'
require 'azure_mgmt_network'
require 'azure_mgmt_storage'

::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)
::Chef::Recipe.send(:include, Azure::ARM::Storage)
::Chef::Recipe.send(:include, Azure::ARM::Storage::Models)
def remove_blob(blob_uri,storage_account,access_key)
  cloud_name = node['workorder']['cloud']['ciName']
  Chef::Log.info('cloud_name is: ' + cloud_name)
  compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']
  begin
  ##### Main #######
  Chef::Log.info('blob_uri : ' + blob_uri )
  container_name = "vhds"
  blob_name =blob_uri.split("/").last
  Chef::Log.info('  blob_name : ' +  blob_name )
  uri_str ="https://"+storage_account+".blob.core.windows.net/"+container_name+"/"+blob_name
  uri = URI.parse(uri_str)

  Chef::Log.debug("uri -- "+uri.to_s)
  time_now= Time.now.httpdate
  Chef::Log.debug("time is "+time_now.to_s)
  date_str = "x-ms-date:"+time_now+"\nx-ms-version:2009-09-19"
  canonical_resource_str = "/"+storage_account+"/"+container_name+"/"+blob_name

    stringToSign  = []
    stringToSign << "DELETE\n\n\n\n\n\n\n\n\n\n\n"
    stringToSign << date_str.to_s
    stringToSign << canonical_resource_str

    stringToSign = stringToSign.join("\n")
    Chef::Log.debug("stringToSign:"+stringToSign)
    keystr = Base64.strict_decode64(access_key)

    signature    = OpenSSL::HMAC.digest('sha256', keystr, stringToSign.encode(Encoding::UTF_8))
    signature    = Base64.strict_encode64(signature)


  auth_str = "SharedKey "+storage_account+":"+signature
  Chef::Log.debug( "auth_str:"+auth_str)
  RestClient.proxy = ENV['http_proxy']
  Chef::Log.debug(RestClient.proxy)
  RestClient.delete uri_str,{:authorization => auth_str, :'x-ms-version' =>'2009-09-19', :'x-ms-date' => time_now}
  rescue Exception => ex
    Chef::Log.error("***FAULT:FATAL=#{ex.message}")
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e
  end
end

remove_blob(node['vhd_uri'],node['storage_account'],node['storage_key1'])

remove_blob(node['datadisk_uri'],node['storage_account'],node['storage_key1'])
