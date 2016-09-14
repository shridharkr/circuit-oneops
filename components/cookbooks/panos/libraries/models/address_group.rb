class AddressGroup

  attr_reader :name, :type, :criteria, :tags

  module Type
    STATIC = 'Static'
    DYNAMIC = 'Dynamic'
  end

  def initialize(name, type, criteria, tags = nil)
    fail ArgumentError, 'name cannot be nil' if name.nil?
    fail ArgumentError, 'type cannot be nil' if type.nil?
    fail ArgumentError, "type, #{type}, is not valid" if !is_valid_type?(type)
    fail ArgumentError, 'criteria cannot be nil' if criteria.nil?

    super()
    @name = name
    @type = type
    @criteria = criteria
    @tags = tags
  end

  def is_valid_type?(type)
    if ( (Type::STATIC.casecmp(type) == 0) ||
         (Type::DYNAMIC.casecmp(type) == 0) )
      return true
    else
      return false
    end
  end

end
