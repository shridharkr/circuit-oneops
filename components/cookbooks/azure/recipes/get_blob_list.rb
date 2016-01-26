require 'time'
require 'uri'
require 'OpenSSL'
require 'base64'
require 'net/https'
require 'net/http'
require 'rest_client'
require 'nokogiri'

::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)
::Chef::Recipe.send(:include, Azure::ARM::Storage)
::Chef::Recipe.send(:include, Azure::ARM::Storage::Models)

def create_signature(storage_account='',time_now='',access_key='')
date_str = "x-ms-date:"+time_now+"\nx-ms-version:2009-09-19"
canonical_resource_str = "/"+storage_account+"/"+"vhds\ncomp:list\nrestype:container"

  stringToSign  = []
  stringToSign << "GET\n\n\n\n\n\n\n\n\n\n\n"
  stringToSign << date_str.to_s
  stringToSign << canonical_resource_str
  stringToSign = stringToSign.join("\n")
  Chef::Log.debug("stringToSign:"+stringToSign)
  keystr = Base64.strict_decode64(access_key)
  signature    = OpenSSL::HMAC.digest('sha256', keystr, stringToSign.encode(Encoding::UTF_8))
  signature    = Base64.strict_encode64(signature)
  Chef::Log.debug("signature:"+signature)
  return signature
end


##### Main #######

container_name = "vhds"
uri_str ="https://"+node['storage_account']+".blob.core.windows.net/vhds?restype=container&comp=list"
uri = URI.parse(uri_str)
Chef::Log.debug("Get Blob list uri -- "+uri.to_s)
access_key = node['storage_key1']
time= Time.now.httpdate
signature =create_signature(node['storage_account'],time.to_s,access_key)
auth_str = "SharedKey "+node['storage_account']+":"+signature
Chef::Log.debug("auth_str:"+auth_str)
RestClient.proxy = ENV['http_proxy']
Chef::Log.debug('Get List of blobs in the conatiner VHDS under storage account:'+node['storage_account'])
response = RestClient.get uri_str,{:authorization => auth_str, :'x-ms-version' =>'2009-09-19', :'x-ms-date' => time}
node.set['blobs'] =  Nokogiri::XML(response)
