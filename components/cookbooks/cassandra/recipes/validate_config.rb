#
# cassandra::validate_config
#

immutable_attrs = [
  "data_file_directories",
  "saved_caches_directory",
  "commitlog_directory"
]

# check for changes - previous value is in ciBaseAttributes
if node.workorder.rfcCi.has_key?("ciBaseAttributes") &&
   node.workorder.rfcCi.ciBaseAttributes.has_key?("config_directives")

  old_cfg = JSON.parse(node.workorder.rfcCi.ciBaseAttributes.config_directives)
  cfg = JSON.parse(node.workorder.rfcCi.ciAttributes.config_directives)
  
  immutable_attrs.each do |immutable_attr|
    if ( cfg.has_key?(immutable_attr) && old_cfg.has_key?(immutable_attr)  &&  # changed
         cfg[immutable_attr] != old_cfg[immutable_attr]) ||
       (!cfg.has_key?(immutable_attr) && old_cfg.has_key?(immutable_attr)) ||  # removed
       (node.workorder.rfcCi.rfcAction == "update" &&
        cfg.has_key?(immutable_attr) && !old_cfg.has_key?(immutable_attr))     # added
        
       action = "The value cannot change for #{immutable_attr}. Please cancel current deployment and "
       if old_cfg.has_key?(immutable_attr)
         action += "change option #{immutable_attr} back to #{old_cfg[immutable_attr]}"       
       else
         action += "remove option: #{immutable_attr}"
       end  
       msg = "#{immutable_attr} cannot be changed. #{action}"
       Chef::Log.error("#{msg}")
       puts "***FAULT:FATAL="+msg
       e = Exception.new("no backtrace")
       e.set_backtrace("")
       raise e       
    end
  end
end
