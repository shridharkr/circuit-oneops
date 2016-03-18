#
#  Helper recipe to populate the dbaas ci attributes
#
#  Author : Jayesh Pise 
#  Copyright WalmartLabs, All rights reserved.


ci = node.workorder.rfcCi.ciAttributes

node.set[:playapp][:http_port] = ci['http_port'].to_i
#node.set[:playapp][:https_port] = ci['httpsport'].empty? ? nil : ci['httpsport'].to_i
#node.set[:playapp][:log_file] = ci['log_file']
#node.set[:playapp][:application_conf_file] = ci['application_conf_file']
node.set[:playapp][:app_name] = ci['app_name']
node.set[:playapp][:app_secret] = ci['app_secret']
#node.set[:playapp][:app_opts] = ci['app_opts']
#node.set[:playapp][:app_dir] = ci['app_dir'].empty? ? nil : ci['app_dir']
node.set[:playapp][:app_location] = ci['app_location']

