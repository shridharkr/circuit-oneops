username = node[:user][:username]
params = "-userName '#{username}'"

delete_user_script = "C:#{Chef::Config[:file_cache_path]}/cookbooks/User/files/default/delete_user.ps1"
Chef::Log.info("Script path: #{delete_user_script}")
cmd = "#{delete_user_script} #{params}"
Chef::Log.info("cmd: #{cmd}")

powershell_script "run delete_user script" do
  code cmd
end
