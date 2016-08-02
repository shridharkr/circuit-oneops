require File.expand_path('../dataaccess/tag_request.rb', __FILE__)
require File.expand_path('../dataaccess/address_group_request.rb', __FILE__)
require File.expand_path('../dataaccess/key_request.rb', __FILE__)
require File.expand_path('../models/key.rb', __FILE__)
require File.expand_path('../dataaccess/address_request.rb', __FILE__)
require File.expand_path('../models/address.rb', __FILE__)
require File.expand_path('../dataaccess/commit_request.rb', __FILE__)
require File.expand_path('../models/panos_job.rb', __FILE__)
require File.expand_path('../dataaccess/status_request.rb', __FILE__)
require File.expand_path('../models/status.rb', __FILE__)

# this class handles coordinating with the request classes to perform operations on
# the PANOS firewall device
class AddressManager

  # initialize the manager class with a URL, username, and password
  def initialize(url, username, password)
    # get the key
    keyrequest = KeyRequest.new(url, username, password)
    @key = keyrequest.getkey()
    @url = url
  end

  # This function handles updating the firewall device
  def update(name, new_ip)
    # check if old address is configured in PANOS
    address = AddressRequest.new(@url, @key)

    # should use the name instead of the ip?
    if address.exists?(name)
      # set the new ip value on the object
      # TODO the naming here is awful.  fix it.
      address.address.address = new_ip

      # update the address
      address.update(address.address)

      commit_and_check_status()
    else
      Chef::Log.info("address is not on firewall, won't update")
    end
  end

  def create_dag_with_addresses(address_group_name, addresses, tag)
    # create the tag that will be used
    tag_request = TagRequest.new(@url, @key)
    tag_request.create(tag)

    # create a DAG
    dag_request = AddressGroupRequest.new(@url, @key)
    dag_request.create_dynamic(address_group_name, tag)

    # create the address
    address_request = AddressRequest.new(@url, @key)
    addresses['entries'].each do |address|
      Chef::Log.info("Address is: #{address}")
      Chef::Log.info("NAME is: #{address['name']}")
      Chef::Log.info("IP Address is: #{address['ip_address']}")
      address_request.create(address['name'], address['ip_address'], tag)
    end

    commit_and_check_status()
  end

  def delete_addresses_and_dag(address_group_name, addresses)
    # delete the addresses
    address_request = AddressRequest.new(@url, @key)
    addresses['entries'].each do |address|
      Chef::Log.info("Address is: #{address}")
      Chef::Log.info("NAME is: #{address['name']}")
      address_request.delete(address['name'])
    end

    # delete the dag
    dag_request = AddressGroupRequest.new(@url, @key)
    dag_request.delete(address_group_name)

    commit_and_check_status()
  end

  private

  # reusable function to commit the changes to the firewall and check the status
  # of the async job that is queued.
  def commit_and_check_status()
    # commit the changes on the firewall device
    commit = CommitRequest.new(@url, @key)
    job = commit.commit_configs

    # check status until complete
    # won't continue until the update is complete.
    status = StatusRequest.new(@url, @key)
    until status.job_complete?(job) do
      Chef::Log.info("job, #{job.id} still in progress")
      sleep(5)
    end

    Chef::Log.info("Job, #{job.id} complete!")
  end

end
