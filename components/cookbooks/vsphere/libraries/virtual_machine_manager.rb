require 'fog'

class VirtualMachineManager
  def initialize(compute_provider, public_key, instance_id = nil)
    fail ArgumentError, 'compute_provider is invalid' if compute_provider.nil?
    fail ArgumentError, 'public_key is invalid' if public_key.nil?

    @compute_provider = compute_provider
    @instance_id = instance_id
    @public_key = public_key
  end

  attr_reader :instance_id

  def ip_address
    ip_address = get_ip_address
  end

  def inject_public_Key
    fail ArgumentError, 'instance_id is invalid' if @instance_id.nil? || @instance_id.empty?

    options = {}
    options['instance_uuid'] = @instance_id
    options['user'] = 'root'
    options['password'] = ''
    options['command'] = '/usr/bin/echo'
    options['args'] = @public_key.chomp + ' > authorized_keys'
    options['working_dir'] = '/root/.ssh'

    time_to_live = 300
    start_time = Time.now
    is_public_key_injected = false
    loop do
      begin
        @compute_provider.vm_execute(options)
        is_public_key_injected = true
        break
      rescue
        Chef::Log.info("waiting for instance to power on 10sec; TTL is " + time_to_live.to_s + " seconds")
        sleep(10)
        break if Time.now > start_time + time_to_live
      end
    end
    return is_public_key_injected
  end
  private :inject_public_Key

  def get_ip_address
    fail ArgumentError, 'instance_id is invalid' if @instance_id.nil? || @instance_id.empty?

    time_to_live = 180
    start_time = Time.now
    ip_address = nil
    loop do
      response = @compute_provider.get_virtual_machine(@instance_id)
      ip_address = response['ipaddress']
      if !ip_address.nil?
        break
      else
        Chef::Log.info("waiting for ip address 10sec; TTL is " + time_to_live.to_s + " seconds")
        sleep(10)
        break if Time.now > start_time + time_to_live
      end
    end
    return ip_address
  end
  private :get_ip_address

  def power_on
    fail ArgumentError, 'instance_id is invalid' if @instance_id.nil? || @instance_id.empty?

    is_power_on = false
    Chef::Log.info("waiting for instance to power on")
    begin
      @compute_provider.vm_power_on({'instance_uuid' => @instance_id})
      is_public_key_injected = inject_public_Key
      if is_public_key_injected
        ip_address = get_ip_address
        is_power_on = true if !ip_address.nil?
      end
    rescue
      Chef::Log.error('Powering on instance failed:' + e.to_s)
      exit 1
    end
    return is_power_on
  end
  private :power_on

  def clone(vm_attributes)
    begin
      new_vm = @compute_provider.vm_clone(vm_attributes)
      @instance_id = new_vm['new_vm']['id']
      power_on
    rescue
      Chef::Log.error('Cloning instance failed:' + e.to_s)
      exit 1
    end
    return @instance_id
  end

  def power_off(force)
    fail ArgumentError, 'instance_id is invalid' if @instance_id.nil? || @instance_id.empty?

    options = {}
    options['instance_uuid'] = @instance_id
    options['force'] = force
    @compute_provider.vm_power_off(options)

    time_to_live = 180
    start_time = Time.now
    is_power_off = false
    loop do
      response = @compute_provider.get_virtual_machine(@instance_id)
      power_state = response['power_state']
      if power_state == 'poweredOff'
        is_power_off = true
        break
      else
        Chef::Log.info("waiting for instance to power off 10sec; TTL is " + time_to_live.to_s + " seconds")
        sleep(10)
        break if Time.now > start_time + time_to_live
      end
    end
    return is_power_off
  end
  private :power_off

  def reboot
    is_rebooted = false
    begin
      is_power_off = power_off(force = false)
      if is_power_off == true
        is_power_on = power_on
        is_rebooted = true if is_power_on == true
      end
    rescue => e
      Chef::Log.error('Rebooting instance failed:' + e.to_s)
      exit 1
    end
    return is_rebooted
  end

  def powercycle
    is_powercycled = false
    begin
      is_power_off = power_off(force = true)
      if is_power_off == true
        is_power_on = power_on
        is_rebooted = true if is_power_on == true
      end
    rescue => e
      Chef::Log.error('Rebooting instance failed:' + e.to_s)
      exit 1
    end
    return is_powercycled
  end

  def get_virtual_machine
    fail ArgumentError, 'instance_id is invalid' if @instance_id.nil? || @instance_id.empty?

    virtual_machine = nil
    begin
      virtual_machine = @compute_provider.get_virtual_machine(@instance_id)
    rescue
      virtual_machine = nil
    end
    return virtual_machine
  end
  private :get_virtual_machine

  def delete
    fail ArgumentError, 'instance_id is invalid' if @instance_id.nil? || @instance_id.empty?

    is_deleted = false
    begin
      virtual_machine = get_virtual_machine
      if !virtual_machine.nil?
        if power_off(force = true)
          response = @compute_provider.vm_destroy({'instance_uuid' => @instance_id})
          is_deleted = true if response['task_state'] == 'success'
        end
      else
        Chef::Log.warn("VM Not Found")
      end
    rescue => e
      Chef::Log.error('Deleting instance failed: ' + e.to_s)
      exit 1
    end
    return is_deleted
  end
end
