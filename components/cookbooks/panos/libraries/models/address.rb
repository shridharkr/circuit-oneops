class Address

  attr_reader :name, :type, :tags

  attr_accessor :address

  module Type
    IP_NETMASK = 'IP_Netmask'
    IP_RANGE = 'IP_Range'
    FQDN = 'FQDN'
  end

  def initialize(name, type, address, tags = nil)
    fail ArgumentError, 'name cannot be nil' if name.nil?
    fail ArgumentError, 'type cannot be nil' if type.nil?
    fail ArgumentError, "type, #{type}, is not valid" if !is_valid_type?(type)
    fail ArgumentError, 'address cannot be nil' if address.nil?
    fail ArgumentError, 'address is not the correct format' if !(address =~ Resolv::IPv4::Regex)

    super()
    @name = name
    @type = type
    @address = address
    @tags = tags
  end

  def is_valid_type?(type)
    if ( (Type::IP_NETMASK.casecmp(type) == 0) ||
         (Type::IP_RANGE.casecmp(type) == 0) ||
         (Type::FQDN.casecmp(type) == 0) )
      return true
    else
      return false
    end
  end

  # override the == method to check if two Address objects equal based on name
  def ==(another_address)
    self.name == another_address.name
  end

end
