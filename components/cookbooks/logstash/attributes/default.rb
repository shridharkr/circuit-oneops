settings = Chef::DataBagItem.load('logstash', 'settings')[node.chef_environment] rescue {}
Chef::Log.debug "Loaded settings: #{settings.inspect}"

# Initialize the node attributes with node attributes merged with data bag attributes
#
node.default[:logstash] ||= {}
node.normal[:logstash]  ||= {}
node.normal[:logstash]    = DeepMerge.merge(node.default[:logstash].to_hash, node.normal[:logstash].to_hash)
node.normal[:logstash]    = DeepMerge.merge(node.normal[:logstash].to_hash, settings.to_hash)


# === VERSION AND LOCATION
#
default.logstash[:version]       = "1.4.2"
default.logstash[:host]          = "http://gec-maven-nexus.walmart.com/nexus/content/repositories/thirdparty/"
default.logstash[:repository]    = "net/sf/logstash/#{node.logstash[:version]}"
default.logstash[:filename]      = "logstash-#{node.logstash[:version]}.tar.gz"
default.logstash[:download_url]  = [node.logstash[:host], node.logstash[:repository], node.logstash[:filename]].join('/')