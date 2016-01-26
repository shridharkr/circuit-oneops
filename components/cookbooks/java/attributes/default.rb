#
# Cookbook Name:: java
# Attributes:: java
#
# Copyright 2015, @WalmartLabs.
#

# Default OS architecture
default[:java]['arch'] = 'x64'

# Default value for java update version based on JDK version
default[:java]['9u']['version'] = ''
default[:java]['8u']['version'] = '51'
default[:java]['7u']['version'] = '72'
default[:java]['6u']['version'] = '45'
default[:java]['uversion'] = ''

# Default binary path
default[:java]['binpath'] = ''

# Default package file extension
default[:java]['package']['extn'] = 'tar.gz'

# Default mirror
default[:java][:nexus_mirror] = 'https://nexus.prod.walmart.com/nexus/content/groups/public/oracle'
