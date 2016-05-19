include_pack 'generic_ring'

name         'couchbase'
description  'CouchBase'
type         'Platform'
category     'Database NoSQL'

platform :attributes => {'autoreplace' => 'false'}

# Overriding the default compute
resource 'compute',
         :attributes => {
           'ostype' => 'default-cloud',
           'size' => 'M'
         }

resource 'user-app',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => {'constraint' => '1..1'},
         :attributes => {
             'username' => 'app',
             'description' => 'App-User',
             'home_directory' => '/app/',
             'system_account' => true,
             'sudoer' => true
         }

resource 'couchbase',
         :cookbook => 'oneops.1.couchbase',
         :design => true,
         :requires => {'constraint' => '1..1', 'services' => 'compute,mirror'},
         :attributes => {
             'version' => '2.5.2',
             'port' => '8091',
             'checksum' => '',
             'arch' => 'x86_64',
             'datapath' => '/opt/couchbase/data/',
             'pernoderamquotamb' => '80%',
             'saslpassword' => 'saslpassword',
             'adminuser' => 'Administrator',
             'adminpassword' => 'password'
         },
         :payloads => {
             'cb_cmp' => {
             'description' => 'Get Computes for Couchbase',
             'definition' => '{
                "returnObject": false, 
                "returnRelation": false, 
                "relationName": "bom.DependsOn", 
                "direction": "to", 
                "targetClassName": "bom.oneops.1.Ring", 
                "relations": [ 
                  { "returnObject": false, 
                    "returnRelation": false, 
                    "relationName": "bom.DependsOn", 
                    "direction": "from",
                    "targetClassName": "bom.oneops.1.Couchbase",
                    "relations": [ 
                      {"returnObject": true, 
                       "returnRelation": false, 
                       "relationName": "bom.DependsOn", 
                       "direction": "from",
                       "targetClassName": "bom.oneops.1.Compute"
                      }
                    ]
                  } 
                 ] 
              }'
          }
         }

resource 'bucket',
         :cookbook => 'oneops.1.bucket',
         :design => true,
         :requires => {'constraint' => '1..5'},
         :attributes => {
             'bucketname' => 'test',
             'bucketpassword' => 'password',
             'bucketmemory' => '100',
             'bucketreplica' => '1',
             'adminuser' => 'Administrator',
             'adminpassword' => 'password'
         },
         :payloads => {
              'cb' => {
              'description' => 'Bucket',
              'definition' => '{
                 "returnObject": false, 
                 "returnRelation": false, 
                 "relationName": "bom.DependsOn", 
                 "direction": "from", 
                 "targetClassName": "bom.oneops.1.Ring", 
                 "relations": [ 
                   { "returnObject": true, 
                     "returnRelation": false, 
                     "relationName": "bom.DependsOn", 
                     "direction": "from",
                     "targetClassName": "bom.oneops.1.Couchbase" 
                     
                   } 
                  ] 
               }'
             }
            }

resource 'couchbase-cluster',
         :cookbook => 'oneops.1.cb_cluster',
         :design => true,
         :requires => {'constraint' => '1..1'},
         :attributes => {
             'bucketname' => 'test',
             'bucketpassword' => 'password',
             'bucketmemory' => '100',
             'bucketreplica' => '1',
             'adminuser' => 'Administrator',
             'adminpassword' => 'password'
         },
         :payloads => {
             'cm' => {
                 'description' => 'Couchbase Cluster Manager',
                 'definition' => '{
                 "returnObject": false,
                 "returnRelation": false,
                 "relationName": "bom.DependsOn",
                 "direction": "from",
                 "targetClassName": "bom.oneops.1.Ring",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationName": "bom.DependsOn",
                     "direction": "from",
                     "targetClassName": "bom.oneops.1.Couchbase"

                   }
                  ]
               }'
             },
             'cb_buckets' => {
                 'description' => 'Buckets',
                 'definition' => '{
                 "returnObject": false,
                 "returnRelation": false,
                 "relationName": "bom.DependsOn",
                 "direction": "from",
                 "targetClassName": "bom.oneops.1.Ring",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationName": "bom.DependsOn",
                     "direction": "to",
                     "targetClassName": "bom.oneops.1.Bucket"
             }
                  ]
               }'
             }

         }

# overwrite volume and filesystem from generic_ring with new mount point
resource 'volume',
         :requires => {'constraint' => '1..1', 'services' => 'compute'},
         :attributes => {'mount_point' => '/opt/couchbase',
                         'size' => '100%FREE',
                         'device' => '',
                         'fstype' => 'ext4',
                         'options' => ''
         }

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "4369 4369 tcp 0.0.0.0/0", "8091 8092 tcp 0.0.0.0/0", "18091 18092 tcp 0.0.0.0/0", "11214 11215 tcp 0.0.0.0/0", "11209 11211 tcp 0.0.0.0/0", "21100 21299 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

# depends_on
[{:from => 'user-app',  :to => 'compute'},
 {:from => 'couchbase', :to => 'user-app'},
 {:from => 'couchbase', :to => 'compute'},
 {:from => 'couchbase', :to => 'os'},
 {:from => 'couchbase', :to => 'volume'},
 {:from => 'build', :to => 'couchbase'}].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

relation "ring::depends_on::couchbase",
         :except => ['_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'ring',
         :to_resource => 'couchbase',
         :attributes => {"flex" => true, "min" => 3, "max" => 10}

relation "couchbase-cluster::depends_on::ring",
         :except => [ '_default', 'single' ],
         :relation_name => 'DependsOn',
         :from_resource => 'couchbase-cluster',
         :to_resource   => 'ring',
         :attributes    => {"flex" => false}

relation "couchbase-cluster::depends_on::couchbase",
         :only => [ '_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'couchbase-cluster',
         :to_resource   => 'couchbase',
         :attributes    =>{"flex" => false}

relation "bucket::depends_on::ring",
         :except => [ '_default', 'single' ],
         :relation_name => 'DependsOn',
         :from_resource => 'bucket',
         :to_resource   => 'ring',
         :attributes    => {"flex" => false}

relation "bucket::depends_on::couchbase",
         :only => [ '_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'bucket',
         :to_resource   => 'couchbase',
         :attributes    =>{"flex" => false}

# managed_via
['user-app','couchbase','bucket','couchbase-cluster','build'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end

# SecuredBy
['couchbase-cluster'].each do |from|
  relation "#{from}::secured_by::sshkeys",
           :except => [ '_default'],
           :relation_name => 'SecuredBy',
           :from_resource => from,
           :to_resource   => 'sshkeys',
           :attributes    => { }
end
