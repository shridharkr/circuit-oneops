name             "Storage"
description      "Storage"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"
depends "shared"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
 :access => "global",
 :packages => [ 'bom' ]

attribute 'size',
  :description => "Size",
  :required => "required",
  :default => "100G",
  :format => { 
    :help => 'Total storage size to be allocated specified in GB (Note: specific raid configurations will result in smaller usable volume size)',
    :category => '1.Configuration',
    :order => 1
  }

attribute 'slice_count',
  :description => "Slice Count",
  :required => "required",
  :default => "1",
  :format => { 
    :help => 'Number of slices / block storage volumes (Note: needs to be even number if you intend to use it for raid10 or raid1 volumes)',
    :category => '1.Configuration',
    :order => 2,
    :patter => "[0-9]+",
    :editable => true
  }
   
# maps provider vol-id for md
attribute 'device_map',
  :description => "Device Map",
  :grouping => "bom",
  :default => "",
  :format => { 
    :help => 'Resulting device map after allocation of the storage resources',
    :category => '2.Devices',
    :order => 1
  } 


recipe "repair", "Repair Storage"
