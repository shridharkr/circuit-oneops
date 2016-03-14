settings = Chef::DataBagItem.load('logstash', 'settings')[node.chef_environment] rescue {}
Chef::Log.debug "Loaded settings: #{settings.inspect}"

# Initialize the node attributes with node attributes merged with data bag attributes
#
node.default[:logstash] ||= {}
node.normal[:logstash]  ||= {}
node.normal[:logstash]    = DeepMerge.merge(node.default[:logstash].to_hash, node.normal[:logstash].to_hash)
node.normal[:logstash]    = DeepMerge.merge(node.normal[:logstash].to_hash, settings.to_hash)

default.logstash[:download_url]  = "https://download.elastic.co/logstash/logstash/logstash-1.5.6.tar.gz"
