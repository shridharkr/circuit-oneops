name             'Firewall'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'Installs/Configures firewall'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
depends          'panos'

grouping 'default',
 :access => "global",
 :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom', 'mgmt.cloud.service', 'cloud.service' ],
 :namespace => true
