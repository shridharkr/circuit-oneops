#
# Cookbook Name:: netscaler
# Resource:: lbvserver
#
actions :create, :delete
default_action :create

attribute :name, 
  :name_attribute => true, 
  :kind_of => String,
  :required => true 
  
attribute :port, 
  :kind_of => String,
  :required => true, 
  :callbacks => {
                  "not in valid numeric range" => lambda { |m|
                    Integer(m)<=65535 && Integer(m)>=1
                  }
                }
                
attribute :servicetype, 
  :kind_of => String,
  :required => true

attribute :lbmethod, 
  :kind_of => String

attribute :ipv46, 
  :kind_of => String
   
attribute :stickiness,
  :kind_of => String

attribute :persistence_type,
  :kind_of => String  
                    
attribute :backupvserver,
  :kind_of => String        
              
attribute :connection, 
  :kind_of => Object,
  :required => true 

