#
# Cookbook Name :: solrcloud
# Recipe :: embeddedzookeeper.rb
#
# The recipe sets up the solrcloud with embedded zookeeper mode on the node.
#

ci = node.workorder.rfcCi.ciAttributes;
solr_base_url = ci['solr_url']
solr_package_type = ci['solr_package_type']
solr_format = ci['solr_format']

solr_download_path = "/tmp";
solr_file_name = "#{solr_package_type}-"+node['solr_version']+".#{solr_format}"
solr_file_woext = "#{solr_package_type}-"+node['solr_version']
solr_url = "#{solr_base_url}/#{solr_package_type}/"+node['solr_version']+"/#{solr_file_name}"
solr_file_path = "#{solr_download_path}/#{solr_file_name}"

if node['solr_version'].start_with? "4."
	port_no = "8080"
end

if (node['solr_version'].start_with? "6.") || (node['solr_version'].start_with? "5.")
	port_no = ci['port_no']
end


zkp_port_no = Integer(port_no)+1000

remote_file solr_file_path do
  source "#{solr_url}"
  owner node['solr']['user']
  group node['solr']['user']
  mode '0644'
  action :create_if_missing
end

bash 'unpack_solr_war' do
	cwd node['user']['dir']
    code <<-EOH
    	mv #{solr_download_path}/#{solr_file_name} #{node['user']['dir']}
    	tar -xf #{solr_file_name}
    	cd #{solr_file_woext}/bin
    	./solr start -c -p #{port_no}
    EOH
end


port_num_list = ci['port_num_list']
num_instances = ci['num_instances']

port_nums = port_num_list.split(",")

if (Integer(port_nums.size) == Integer(num_instances)) && (Integer(num_instances) > 0)
	i = Integer("2")
	port_nums.each do |port|
		bash 'rename_dir_and_start' do
			cwd node['user']['dir']
			code <<-EOH
				cp -r #{solr_file_woext} #{solr_file_woext}-#{i}
				cd #{solr_file_woext}-#{i}/bin
				./solr start -c -p #{port} -z localhost:#{zkp_port_no}
			EOH
		end
		i = i + 1
	end
end



