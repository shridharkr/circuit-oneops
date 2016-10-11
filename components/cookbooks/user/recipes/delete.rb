if node[:workorder][:rfcCi][:ciAttributes][:ostype] =~ /windows/
  username = node[:user][:username]
  params = "-userName '#{username}'"

  delete_user_script = "#{Chef::Config[:file_cache_path]}/cookbooks/user/files/default/delete_user.ps1"
  Chef::Log.info("Script path: #{delete_user_script}")
  cmd = "#{delete_user_script} #{params}"
  Chef::Log.info("cmd: #{cmd}")

  powershell_script "run delete_user script" do
    code cmd
  end

else
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
end
