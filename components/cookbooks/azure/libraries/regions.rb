#require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)
# AzureRegions class to have all the Azure-Regions to Region Code mappings

module AzureRegions

  class RegionName

    # this is a static method to generate a name based on a ciId and location.
    def self.abbreviate(region)
      abbr = ''

      # Resouce Group name can only be 90 chars long.  We are doing this case
      # to abbreviate the region so we don't hit that limit.
      case region
        when 'eastus2'
          abbr = 'eus2'
        when 'centralus'
          abbr = 'cus'
        when 'brazilsouth'
          abbr = 'brs'
        when 'centralindia'
          abbr = 'cin'
        when 'eastasia'
          abbr = 'eas'
        when 'eastus'
          abbr = 'eus'
        when 'japaneast'
          abbr = 'jpe'
        when 'japanwest'
          abbr = 'jpw'
        when 'northcentralus'
          abbr = 'ncus'
        when 'northeurope'
          abbr = 'neu'
        when 'southcentralus'
          abbr = 'scus'
        when 'southeastasia'
          abbr = 'seas'
        when 'southindia'
          abbr = 'sin'
        when 'westeurope'
          abbr = 'weu'
        when 'westindia'
          abbr = 'win'
        when 'westus'
          abbr = 'wus'
        else
          OOLog.fatal("Azure location/region, '#{region}' not found in Resource Group abbreviation List")
      end
      return abbr
    end

  end

end
