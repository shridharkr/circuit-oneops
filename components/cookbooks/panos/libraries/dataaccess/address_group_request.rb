

class AddressGroupRequest

  # initialize the class making sure we have a URL endpoint and a KEY to use when communicating
  # to the firewall device
  def initialize(url, key)
    fail ArgumentError, 'url cannot be nil' if url.nil?
    fail ArgumentError, 'key cannot be nil' if key.nil?
    fail ArgumentError, 'key must be of type Key' if !key.is_a? Key

    @baseurl = url
    @key = key
  end

  def create_dynamic(name, filter, device_group)
    begin
    	set_ag_response = RestClient::Request.execute(
    		:method => :post,
    		:verify_ssl => false,
    		:url => @baseurl,
    		:headers => {
    			:params => {
    				:key => @key.value,
    				:type => 'config',
    				:action => 'set',
    				:xpath => "/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='#{device_group}']/address-group",
    				:element => "<entry name='#{name}'><dynamic><filter>'#{filter}'</filter></dynamic></entry>"
    			}
    		}
    	)
      dag_hash = Crack::XML.parse(set_ag_response)
      Chef::Log.info("dag_hash is: #{dag_hash}")
      raise Exception.new("PANOS Error creating a DAG: #{dag_hash['response']['msg']}") if dag_hash['response']['status'] == 'error'
    rescue => e
      raise Exception.new("Exception creating DAG: #{e} ")
    end
  end

  def delete(name, device_group)
    begin
    	delete_ag_response = RestClient::Request.execute(
    		:method => :post,
    		:verify_ssl => false,
    		:url => @baseurl,
    		:headers => {
    			:params => {
    				:key => @key.value,
    				:type => 'config',
    				:action => 'delete',
            :xpath => "/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='#{device_group}']/address-group/entry[@name='#{name}']"
    			}
    		}
    	)
      dag_hash = Crack::XML.parse(delete_ag_response)
      Chef::Log.info("delete_dag_hash is: #{dag_hash}")
      raise Exception.new("PANOS Error deleting a DAG: #{dag_hash['response']['msg']}") if dag_hash['response']['status'] == 'error'
    rescue => e
      raise Exception.new("Exception deleting DAG: #{e} ")
    end
  end

end
