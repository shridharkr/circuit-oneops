include_pack "base"

name "genericmq"
description "Queue and topic"
ignore true
type "Platform"
category "Messaging"


resource "queue",
  :cookbook => "oneops.1.queue",
  :design => true,
  :requires => { 
      :constraint => "0..*",
      :help => 'Queues'
    },
    :payloads => {
           'activemq' => {
             :description => 'Activemq',
             :definition  => '{
                "returnObject": true,
                "returnRelation": false,
                "relationName": "bom.DependsOn",
                "direction": "from",
                "targetClassName": "bom.Activemq"
              }'
           }
         } ,
   :monitors => {
      'QueueStatus' =>  { 
            :description => 'QueuesStatus',
            :source => '',
            :chart => {'min'=>0, 'unit'=>''},
           :cmd => 'check_queue!#{cmd_options[:protocol]}!#{cmd_options[:port]}!#{cmd_options[:path]}!:::node.workorder.rfcCi.ciAttributes.queuename:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:authenabled]:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:adminusername]:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:adminpassword]:::',
            :cmd_line => '/opt/nagios/libexec/check_queue.rb $ARG1$ $ARG2$ $ARG3$ $ARG4$ $ARG5$ $ARG6$ $ARG7$',
            :cmd_options => {
              'protocol' => 'http',
               'port' => '8161',
               'path' => '/admin/xml/queues.jsp'
            },
            :metrics =>  {
              'queue_pending_count'   => metric( 
                  :unit => 'PerSecond', 
                  :description => 'Pending Messages /sec'),
              'queue_consumer_count'   => metric( 
                  :unit => '', 
                  :description => 'Queue Consumer Count'),
              'queue_enqueues'   => metric( 
                  :unit => 'PerSecond', 
                  :description => 'Queue in messages /sec', :dstype => 'DERIVE'),
              'queue_dequeues'   => metric( 
                  :unit => 'PerSecond', 
                  :description => 'Queue out messages /sec' ,:dstype => 'DERIVE')
            }          
        } 
  }
  
resource "topic",
  :cookbook => "oneops.1.topic",
  :design => true,
  :requires => { 
      :constraint => "0..*",
      :help => 'Topic'
    },
    :payloads => {
           'activemq' => {
             :description => 'Activemq',
             :definition  => '{
                "returnObject": true,
                "returnRelation": false,
                "relationName": "bom.DependsOn",
                "direction": "from",
                "targetClassName": "bom.Activemq"
              }'
           }
         }  ,
   :monitors => {
      'TopicStatus' =>  { 
            :description => 'TopicStatus',
            :source => '',
            :chart => {'min'=>0, 'unit'=>''},
            :cmd => 'check_topic!#{cmd_options[:protocol]}!#{cmd_options[:port]}!#{cmd_options[:path]}!:::node.workorder.rfcCi.ciAttributes.topicname:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:authenabled]:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:adminusername]:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:adminpassword]:::',
            :cmd_line => '/opt/nagios/libexec/check_topic.rb $ARG1$ $ARG2$ $ARG3$ $ARG4$ $ARG5$ $ARG6$ $ARG7$' ,
            :cmd_options => {
               'protocol' => 'http',
               'port' => '8161',
               'path' => '/admin/xml/topics.jsp'
            },
            :metrics =>  {
              'topic_pending_count'   => metric( 
                  :unit => 'PerSecond', 
                  :description => 'Pending Messages /sec'),
              'topic_consumer_count'   => metric( 
                  :unit => '', 
                  :description => 'Topic Consumer Count'),
              'topic_enqueues'   => metric( 
                  :unit => 'PerSecond', 
                  :description => 'Topic in messages /sec' ,:dstype => 'DERIVE'),
              'topic_dequeues'   => metric( 
                  :unit => 'PerSecond', 
                  :description => 'Topic out messages /sec', :dstype => 'DERIVE')
            }          
        } 
  } 

# depends on
relation "fqdn::depends_on::compute",
  :only => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 }

relation "fqdn::depends_on_flex::compute",
  :except => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "flex" => true, "min" => 2, "max" => 10 }


 # managed_via
['queue', 'topic'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end
