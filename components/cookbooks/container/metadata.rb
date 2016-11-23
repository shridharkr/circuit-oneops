name             "Container"
description      "Container spec"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => [ 'bom' ]


# Image

attribute 'image_type',
  :description => "Image Type",
  :required => "required",
  :default => "registry",
  :format => {
    :category => '1.Image',
    :important => true,
    :help => 'Select image type',
    :order => 1,
    :form => {
      'field' => 'select',
      'options_for_select' => [
        ['Use image from registry','registry'],
        ['Build image using Dockerfile','dockerfile']
      ]
    }
  }

# registry
attribute 'image',
  :description => "Image Name",
  :default => "alpine",
  :format => {
    :help => 'Reference to an image name in the registry',
    :category => '1.Image',
    :important => true,
    :order => 2,
    :filter => {:all => {:visible => 'image_type:eq:registry'}}
  }

# dockerfile
attribute 'dockerfile',
  :description => 'Dockerfile Content',
  :data_type => "text",
  :default => '',
  :format => {
    :help => 'Insert Dockerfile content needed to create the image',
    :category => '1.Image',
    :order => 3,
    :tip => 'Leave empty to use Dockerfile from the URL context',
    :filter => {:all => {:visible => 'image_type:eq:dockerfile'}}
  }

attribute 'url',
  :description => 'URL',
  :default => '',
  :format => {
    :help => 'URL context per https://docs.docker.com/engine/reference/commandline/build/',
    :category => '1.Image',
    :order => 4,
    :filter => {:all => {:visible => 'image_type:eq:dockerfile'}}
  }

attribute 'tag',
  :description => "Tag",
  :default => 'latest',
  :format => {
    :help => 'Use cache when building the image',
    :category => '1.Image',
    :order => 5,
    :filter => {:all => {:visible => 'image_type:eq:dockerfile'}}
  }

attribute 'cache',
  :description => "Cache",
  :default => 'true',
  :format => {
    :help => 'Use cache when building the image',
    :category => '1.Image',
    :form => { 'field' => 'checkbox' },
    :order => 6,
    :filter => {:all => {:visible => 'image_type:eq:dockerfile'}}
  }



# Run
attribute 'command',
  :description => "Command",
  :format => {
    :help => 'Command to use as entrypoint to start the container',
    :category => '2.Run',
    :order => 1
  }

attribute 'args',
  :description => "Arguments",
  :data_type => "array",
  :default => '[]',
  :format => {
    :help => 'Command arguments to use as entrypoint to start the container',
    :category => '2.Run',
    :order => 2
  }

attribute 'env',
  :description => "Environment Variables",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => '',
    :category => '2.Run',
    :order => 3
  }

attribute 'ports',
  :description => "Ports",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Map of port name (a DNS_LABEL) and value as <port-number>[/<port-protocol>]. Example ssh=22/tcp',
    :important => true,
    :category => '2.Run',
    :order => 4
  }


# Resources

attribute 'cpu',
  :description => "CPU",
  :format => {
    :help => 'CPUs to reserve for each container. Default is whole CPUs; scale suffixes (e.g. 100m for one hundred milli-CPUs) are supported',
    :category => '3.Resources',
    :order => 1
  }

attribute 'memory',
  :description => "Memory",
  :format => {
    :help => 'Memory to reserve for each container. Default is bytes; binary scale suffixes (e.g. 100Mi for one hundred mebibytes) are supported',
    :category => '3.Resources',
    :order => 2
  }

recipe "repair", "Repair"
