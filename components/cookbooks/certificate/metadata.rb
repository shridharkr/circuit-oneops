name             "Certificate"
description      "Certificate"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'key',
  :description => "Key",
  :data_type => "text",
  :encrypted => true,
  :default => "",
  :format => {
    :help => 'Enter the certificate key content (Note: usually this is the content of the *.key file)',
    :category => '1.Certificate',
    :order => 1,
    :filter => {'all' => {'visible' => 'pfx_enable:eq:false'}}
  }

attribute 'cert',
  :description => "Certificate",
  :data_type => "text",
  :default => "",
  :format => {
    :help => 'Enter the certificate content to be used (Note: usually this is the content of the *.crt file)',
    :category => '1.Certificate',
    :order => 2,
    :filter => {'all' => {'visible' => 'pfx_enable:eq:false'}}
  }

attribute 'cacertkey',
  :description => "SSL CA Certificate Key",
  :data_type => "text",
  :default => "",
  :format => {
    :help => 'Enter the CA certificate keys to be used',
    :category => '1.Certificate',
    :order => 3,
    :filter => {'all' => {'visible' => 'pfx_enable:eq:false'}}
  }

attribute 'passphrase',
  :description => "Pass Phrase",
  :encrypted => true,
  :default => "",
  :format => {
    :help => 'Enter the passphrase for the certificate key',
    :category => '1.Certificate',
    :order => 4,
    :filter => {'all' => {'visible' => 'pfx_enable:eq:false'}}
  }

attribute 'pkcs12',
  :description => "Convert to PKCS12",
  :default => 'false',
  :format => {
    :category => '1.Certificate',
    :order => 5,
    :form => { 'field' => 'checkbox' },
    :help => 'Directory path where the certicate files should be saved',
    :filter => {'all' => {'visible' => 'pfx_enable:eq:false'}}
  }

attribute 'path',
  :description => "Directory Path",
  :default => "/var/lib/certs",
  :format => {
    :category => '2.Destination',
    :order => 1,
    :help => 'Directory path where the certicate files should be saved',
    :filter => {'all' => {'visible' => 'pfx_enable:eq:false'}}
  }

attribute 'pfx_enable',
          :description => 'SSL Certificate (PFX)',
          :default => "false",
          :format => {
              :help => 'Enable it to upload .pfx file data for Application Gateway.',
              :category => '3.Application Gateway',
              :order => 1,
              :form => {'field' => 'checkbox'}
          }

attribute 'ssl_data',
          :description => "Data",
          :data_type => "text",
          :default => "",
          :format => {
              :help => 'Enter the base-64 encoded form of the .pfx file.',
              :category => '3.Application Gateway',
              :order => 2,
              :filter => {'all' => {'visible' => 'pfx_enable:eq:true'}}
          }

attribute 'ssl_password',
          :description => "Password",
          :encrypted => true,
          :default => "",
          :format => {
              :help => 'Enter password for a .pfx certificate.',
              :category => '3.Application Gateway',
              :order => 3,
              :filter => {'all' => {'visible' => 'pfx_enable:eq:true'}}
          }
recipe "repair", "Repair"
