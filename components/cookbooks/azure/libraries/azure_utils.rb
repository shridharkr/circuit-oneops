#require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)

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

        OOLog.fatal('Azure Token Provider is nil') if token_provider.nil?

        MsRest::TokenCredentials.new(token_provider)
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error acquiring a token from Azure: #{e.body}")
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
      OOLog.info("ENV VARS ARE: #{compute_service['env_vars']}")
      env_vars_hash = JSON.parse(compute_service['env_vars'])
      OOLog.info("APIPROXY is: #{env_vars_hash['apiproxy']}")

      if !env_vars_hash['apiproxy'].nil?
        ENV['http_proxy'] = env_vars_hash['apiproxy']
        ENV['https_proxy'] = env_vars_hash['apiproxy']
      end
    end

  end
end
