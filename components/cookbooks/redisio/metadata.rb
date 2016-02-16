# Metadata for the redisio cookbook 
# Last Edited and Updated by Ravi Vangara
name             'Redisio'
maintainer       'Brian Bianco'
maintainer_email 'brian.bianco@gmail.com'
license          'Apache 2.0'
description      'Installs/Configures redis'
version          '1.7.0'

#-cookie cutter grouping values
grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


###
###:default => 'http://download.redis.io/releases/redis-2.6.16.tar.gz',
###:default => 'http://download.redis.io/releases/redis-2.6.16.tar.gz',
### attributes here have a one-to-one mapping to attributes defined in the cookbook attribute file (attributes/default.rb) 
attribute 'src_url',
          :description => 'Source URL',
          :required => 'required',
          :default => 'http://gec-maven-nexus.walmart.com/nexus/service/local/repositories/thirdparty/content/redis/io/redis/',
          :format => {
              :help => 'location of the redis source distribution',
              :category => '1.Global',
              :order => 2
          }

#:filter => {"all" => {"visible" => "version:eq:3.0.1"}}
#attribute 'src_url_2_6_16',
#          :description => 'Source URL',
#          :required => 'required',
#          :format => {
#              :help => 'location of the redis source distribution',
#              :category => '1.Global',
#              :order => 2,
#	       #:filter => {"all" => {"visible" => "version:eq:2.6.16"}}
#          }

### support freedom of choice
attribute 'version',
	:description => "Redis Version",
	:required => "required",
	:default => '3.0.1',
	:format => {
    		:category => '1.Global',
    		:help => 'Version of the Redis install',
    		:editable => true,
    		:order => 2,
    		:form => {'field' => 'select', 'options_for_select' => [['2.6.16', '2.6.16'], ['3.0.1', '3.0.1']]}
	}

### Number of Replicas in a Cluster - Default 1
attribute 'replicas',
	:description => "Number of Replicas for Cluster - Usually 1",
	:required => "required",
	:default => '1',
	:format => {
    		:category => '1.Version',
    		:help => 'Number of Replicas in the REDIS cluster',
    		:editable => true,
    		:order => 2,
	        :filter => {"all" => {"visible" => "version:eq:3.0.1"}}
	}

# a description for each recipe, mostly for cosmetic value within the server UI
recipe "start", "Start Redis"
recipe "stop", "Stop Redis"
recipe "repair", "Repair Redis"
