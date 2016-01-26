include_pack "base"

name "docker"
description "Docker"
type "Platform"
category "Infrastructure Service"
ignore true


resource "secgroup",
  :cookbook => "oneops.1.secgroup",
  :design => true,
  :attributes => {
    "inbound" => '[ "22 22 tcp 0.0.0.0/0", "2375 2375 tcp 0.0.0.0/0", "49153 65535 tcp 0.0.0.0/0" ]'
  },
  :requires => {
    :constraint => "1..1",
    :services => "compute"
  }

resource "compute",
  :attributes => {
    "ostype"  => "centos-6.5",
    "size"    => "XL"
  }

resource "volume",
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/docker',
    "device"        => '',
    "fstype"        => 'xfs',
    "options"       => ''
  }

resource "docker",
  :cookbook => "oneops.1.library",
  :design => true,
  :requires => { "constraint" => "1..1" }

resource "docker-config",
  :cookbook => "oneops.1.file",
  :design => true,
  :requires => { :constraint => "1..1" },
  :attributes => {
    "path" => '/etc/sysconfig/docker',
    "exec_cmd" => 'service docker restart',
    "content" => <<-EOS
other_args="$(echo `grep nameserver /etc/resolv.conf | grep -v 127.0.0.1 | sed 's/nameserver/--dns/'`) -g /docker -H tcp://$(hostname):2375 -H unix:///var/run/docker.sock"
EOS
  }

resource "daemon",
  :requires => { "constraint" => "1..*" },
  :attributes => {
    "service_name" => 'docker',
    "control_script_location" => '/etc/init.d/docker'
  }

# depends_on
[ { :from => 'daemon',        :to => 'docker-config' },
  { :from => 'daemon',        :to => 'docker' },
  { :from => 'docker-config', :to => 'docker' },
  { :from => 'docker-config', :to => 'volume' },
  { :from => 'docker',        :to => 'compute'},    
  { :from => 'docker',        :to => 'os' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

relation "fqdn::depends_on::compute",
  :only => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }

relation "fqdn::depends_on_flex::compute",
  :except => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "propagate_to" => 'from', "flex" => true, "min" => 2, "max" => 10 }

# managed_via
[ 'docker','docker-config'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
