#
# Cookbook Name:: solr-monitor
# Recipe:: deploysolrmonitoring.rb
#
# This recipe schedules the cron job.
# @walmartlabs
#

extend Java::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, Java::Util)

ci = node.workorder.rfcCi.ciAttributes;

logical_collection_name = ci[:logical_collection_name]
graphite_server = ci[:graphite_server]
graphite_port = ci[:graphite_port]
app_name = ci[:app_name]
solrcloud_datacenter = ci[:solrcloud_datacenter]
email_addresses = ci[:email_addresses]
solrcloud_env = ci[:solrcloud_env]
solr_monitor_version = ci[:solrmon_version]

if File.file?("#{node['script']['dir']}/crontab-#{solr_monitor_version}.txt")
  Chef::Log.info('#{solr_monitor_version} crontab script exists')
  bash 'cleanuptorecreate' do
    code <<-EOH
      cd "#{node['script']['dir']}"
      rm -rf crontab-#{solr_monitor_version}.txt
      rm -rf #{node['monitor']['dir']}/solr_monitor_crontab.txt
    EOH
  end
end

bash 'createcrontabscript' do 
  code <<-EOH
    cd "#{node['user']['dir']}"
    echo '*/1 * * * * #{node['monitor']['dir']}/solr-monitor/solr_monitor.py -solrcollection #{logical_collection_name} -solrhost http://#{node['ipaddress']}:8080/ -graphiteserver #{graphite_server} -id #{node['ipaddress']} -graphitecollname #{logical_collection_name} -statsprefix #{app_name} -graphiteport #{graphite_port} -defaultemail #{email_addresses} -datacenter #{solrcloud_datacenter} -env #{solrcloud_env}' >> #{node['monitor']['dir']}/solr_monitor_crontab.txt
    echo '*/5 * * * * #{node['monitor']['dir']}/threads-counter/thread_counter_single.sh #{node['ipaddress']} #{app_name} #{solrcloud_env} #{solrcloud_datacenter} #{email_addresses} #{graphite_server} #{graphite_port}' >> #{node['monitor']['dir']}/solr_monitor_crontab.txt
    echo '*/1 * * * * #{node['monitor']['dir']}/gc-full-stops/grepGcFullStops.sh #{node['ipaddress']} #{app_name} #{solrcloud_env} #{solrcloud_datacenter} #{email_addresses} #{graphite_server} #{graphite_port}' >> #{node['monitor']['dir']}/solr_monitor_crontab.txt
  EOH
end

bash 'create_cron_ack_file' do
  code <<-EOH
    cd "#{node['script']['dir']}"
    sudo rm -rf crontab-*.txt
    echo #{solr_monitor_version} > crontab-#{solr_monitor_version}.txt
  EOH
end

Chef::Log.info('Setup CronJob for solr-monitor scripts')
bash 'setcrontab' do
  user "#{node['solr']['user']}"
  code <<-EOH
    sh #{node['monitor']['dir']}/set_crontab.sh
  EOH
end


