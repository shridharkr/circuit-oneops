# Cookbook Name:: redisio
# Attribute::default
#
# Copyright 2013, Brian Bianco <brian.bianco@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node['platform']
when 'ubuntu','debian'
  shell = '/bin/false'
  homedir = '/var/lib/redis'
when 'centos','redhat','scientific','amazon','suse'
  shell = '/bin/sh'
  homedir = '/var/lib/redis' 
when 'fedora'
  shell = '/bin/sh'
  homedir = '/home' #this is necessary because selinux by default prevents the homedir from being managed in /var/lib/ 
else
  shell = '/bin/sh'
  homedir = '/redis'
end

default['version'] = "3.0.1"

# this one added locally for Tarball and download related defaults
#default['redisio']['src_url'] = "http://download.redis.io/releases/redis-2.6.16.tar.gz"
#default['redisio']['src_url'] = "https://github.com/antirez/redis/archive/3.0.0-beta8.tar.gz"



#Install related attributes
default['redisio']['safe_install'] = true
default['redisio']['mirror'] = "$OO_CLOUD{nexus}/nexus/content/repositories/thirdparty/content/redis/io/redis/"
default['redisio']['base_name'] = 'redis-'
default['redisio']['artifact_type'] = 'tar.gz'
default['redisio']['version'] = '3.0.1'
default['redisio']['base_piddir'] = '/var/run/redis'

#Custom installation directory
default['redisio']['install_dir'] = nil

#Default settings for all redis instances, these can be overridden on a per server basis in the 'servers' hash
# this set was in the community cookbook but actually were incompatible out of the box so commented
#_  'syslogenabled'          => 'yes',
#_  'syslogfacility'         => 'local0',
#_  'slaveservestaledata'    => 'yes',
#_  'replpingslaveperiod'    => '10',
#_  'repltimeout'            => '60',
#_  'maxmemorypolicy'        => 'volatile-lru',
#_  'maxmemorysamples'       => '3',
#_  'noappendfsynconrewrite' => 'no',
#_  'aofrewritepercentage'   => '100',
#_  'aofrewriteminsize'      => '64mb',
#_  'ulimit'                 => 0,

default['redisio']['default_settings'] = {
  'user'                   => 'redis',
  'group'                  => 'redis',
  'homedir'                => homedir,
  'shell'                  => shell,
  'systemuser'             => true,
  'configdir'              => '/etc/redis',
  'name'                   => nil,
  'address'                => nil,
  'databases'              => '16',
  'backuptype'             => 'rdb',
  'datadir'                => '/var/lib/redis',
  'unixsocket'             => nil,
  'unixsocketperm'         => nil,
  'timeout'                => '0',
  'loglevel'               => 'verbose',
  'logfile'                => '/log/redis.log',
  'shutdown_save'          => false,
  'save'                   => nil, # Defaults to ['900 1','300 10','60 10000'] inside of template.  Needed due to lack of hash subtraction
  'slaveof'                => nil,
  'job_control'            => 'initd', 
  'masterauth'             => nil,
  'requirepass'            => nil,
  'maxclients'             => 10000,
  'maxmemory'              => nil,
  'appendfsync'            => 'everysec',
  'cluster-enabled'        => 'no',
  'cluster-config-file'    => nil, # Defaults to redis instance name inside of template if cluster is enabled.
  'cluster-node-timeout'   => 5,
  'includes'               => nil
}

default['redisio']['cluster_settings'] = {
  'user'                   => 'redis',
  'group'                  => 'redis',
  'homedir'                => homedir,
  'shell'                  => shell,
  'systemuser'             => true,
  'configdir'              => '/etc/redis',
  'name'                   => nil,
  'address'                => nil,
  'databases'              => '16',
  'backuptype'             => 'rdb',
  'datadir'                => '/var/lib/redis',
  'unixsocket'             => nil,
  'unixsocketperm'         => nil,
  'timeout'                => '0',
  'loglevel'               => 'verbose',
  'logfile'                => '/log/redis.log',
  'shutdown_save'          => false,
  'save'                   => nil, # Defaults to ['900 1','300 10','60 10000'] inside of template.  Needed due to lack of hash subtraction
  'slaveof'                => nil,
  'job_control'            => 'initd', 
  'masterauth'             => nil,
  'requirepass'            => nil,
  'maxclients'             => 10000,
  'maxmemory'              => nil,
  'appendfsync'            => 'everysec',
  'cluster-enabled'        => 'yes',
  'cluster-config-file'    => nil, # Defaults to redis instance name inside of template if cluster is enabled.
  'cluster-node-timeout'   => 5,
  'includes'               => nil
}

# The default for this is set inside of the "install" recipe. This is due to the way deep merge handles arrays
default['redisio']['servers'] = nil

