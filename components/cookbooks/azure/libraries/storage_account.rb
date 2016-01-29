# StorageAccount class to have all the functionality for Storage accounts here.

module AzureStorage

  class StorageAccount

    # this is a static method to generate a name based on a ciId and location.
    def self.generate_name(ciId, location)
      loc = ''

      # storage account name can only be 24 chars long.  We are doing this case
      # to abbreviate the region so we don't hit that limit.
      case location
        when 'eastus2'
          loc = 'eus2'
        when 'centralus'
          loc = 'cus'
        when 'brazilsouth'
          loc = 'brs'
        when 'centralindia'
          loc = 'cin'
        when 'eastasia'
          loc = 'eas'
        when 'eastus'
          loc = 'eus'
        when 'japaneast'
          loc = 'jpe'
        when 'japanwest'
          loc = 'jpw'
        when 'northcentralus'
          loc = 'ncus'
        when 'northeurope'
          loc = 'neu'
        when 'southcentralus'
          loc = 'scus'
        when 'southeastasia'
          loc = 'seas'
        when 'southindia'
          loc = 'sin'
        when 'westeurope'
          loc = 'weu'
        when 'westindia'
          loc = 'win'
        when 'westus'
          loc = 'wus'
      end
      name = "oostg#{ciId}#{loc}"
      name
    end

  end

end