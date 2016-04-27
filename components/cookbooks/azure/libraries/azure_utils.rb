require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)

# Common class for common methods, like get_credentials.

module AzureCommon
  class AzureUtils

    # method to get credentials in order to call Azure
    def self.get_credentials(tenant_id, client_id, client_secret)
      begin
        # Create authentication objects
        token_provider =
          MsRestAzure::ApplicationTokenProvider.new(tenant_id,
                                                    client_id,
                                                    client_secret)
        if !token_provider.nil?
          MsRest::TokenCredentials.new(token_provider)
        else
          e = Exception.new('Could not retrieve azure credentials')
          raise e
        end
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error acquiring a token from Azure: #{e.body.values[0]['message']}")
      rescue => ex
        OOLog.fatal("Error acquiring a token from Azure: #{ex.message}")
      end
    end

    # if there is an apiproxy cloud var define, set it on the env.
    def self.set_proxy(cloud_vars)
      cloud_vars.each do |var|
        if var[:ciName] == 'apiproxy'
          ENV['http_proxy'] = var[:ciAttributes][:value]
          ENV['https_proxy'] = var[:ciAttributes][:value]
        end
      end
    end

    # if there is an apiproxy cloud var define, set it on the env.
    def self.set_proxy_from_env(node)
      cloud_name = node['workorder']['cloud']['ciName']
      compute_service =
        node['workorder']['services']['compute'][cloud_name]['ciAttributes']
      Chef::Log.info("ENV VARS ARE: #{compute_service['env_vars']}")
      env_vars_hash = JSON.parse(compute_service['env_vars'])
      Chef::Log.info("APIPROXY is: #{env_vars_hash['apiproxy']}")

      if !env_vars_hash['apiproxy'].nil?
        ENV['http_proxy'] = env_vars_hash['apiproxy']
        ENV['https_proxy'] = env_vars_hash['apiproxy']
      end
    end

  end
end
