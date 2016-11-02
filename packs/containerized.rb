name "containerized"
description "Containerized Application"
type "Platform"
category "Other"

environment "single", {}
environment "redundant", {}

entrypoint "replication"

platform :attributes => {
                "replace_after_minutes" => 60,
                "replace_after_repairs" => 3
        }

resource "container",
  :cookbook => "oneops.1.container",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "container" }

resource "replication",
  :cookbook => "oneops.1.replication",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "container" }

# depends_on
[ { :from => 'replication',     :to => 'container' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { 'propagate_to' => 'from' }
end
