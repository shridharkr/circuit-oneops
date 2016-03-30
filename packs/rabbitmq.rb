include_pack "generic_ring"

name "rabbitmq"
description "RabbitMQ"
type "Platform"
category "Messaging"

resource 'user-app',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => {'constraint' => "1..1"},
         :attributes => {
             :username => 'app',
             :description => 'App User',
             :home_directory => '/app',
             :system_account => true,
             :sudoer => true
         }
  
resource "rabbitmq",
  :cookbook => "oneops.1.rabbitmq",
  :design => true,
  :requires => { "constraint" => "1..1" },
  :attributes => {
    "version"      => "3.4.2",
    "port"         => "5672",
    "datapath"     => "/data/rabbitmq/mnesia",
    "erlangcookie" => "DEFAULTCOOKIE"
  }

resource "volume",
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/data',
                    "device"        => '',
                    "size"          => '10G',
                    "fstype"        => 'ext4',
                    "options"       => ''                     
                 },
  :monitors => {
      'usage' =>  {'description' => 'Usage',
                  'chart' => {'min'=>0,'unit'=> 'Percent used'},
                  'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                  'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                  'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                                 'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                  :thresholds => {
                    'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                    'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
                  },
                }
    }


resource "volume-log",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/log',
                    "size"          => '100%FREE',
                    "device"        => '',
                    "fstype"        => 'ext4',
                    "options"       => ''
                 },
  :monitors => {
      'usage' =>  {'description' => 'Usage',
                  'chart' => {'min'=>0,'unit'=> 'Percent used'},
                  'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                  'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                  'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                                 'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                  :thresholds => {
                    'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                    'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
                  },
                },
    }
  
# depends_on
[{:from => 'os', :to => 'compute'},
  {:from => 'user-app', :to => 'os'},
  {:from => 'fqdn', :to => 'user-app'},
  {:from => 'volume', :to => 'user-app'},
  {:from => 'volume-log', :to => 'volume'},
  {:from => 'volume-log', :to => 'user-app'},
    {:from => 'rabbitmq', :to => 'volume-log'}].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "5672 5672 tcp 0.0.0.0/0", "5673 5673 tcp 0.0.0.0/0", "15672 15672 tcp 0.0.0.0/0", "25672 25672 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

relation "ring::depends_on::rabbitmq",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'ring',
    :to_resource   => 'rabbitmq',
    :attributes    => { "flex" => true, "min" => 1, "max" => 10 } 

    
# managed_via
[ 'user-app', 'volume-log', 'volume', 'rabbitmq'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end
