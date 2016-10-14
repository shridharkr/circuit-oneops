if node.platform =~ /windows/
  include_recipe "user::windows_user_delete"
  return
end

username = node[:user][:username]

Chef::Log.info("Stopping the nslcd service")
`sudo killall -9  /usr/sbin/nslcd`

if username != "root"
  execute "pkill -9 -u #{username} ; true"
end

user "#{username}" do
  action :remove
end

group "#{username}" do
  action :remove
end
