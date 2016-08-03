Chef::Log.info("Executing WindowsOS::Add recipe ...")

include_recipe "windowsos::install_packages"
include_recipe "os::time"

file 'c:/tmp/first_chef_file' do
  content '<html>This is a placeholder for the home page.</html>'
  mode '0755'
  owner 'admin'
  group 'admin'
end