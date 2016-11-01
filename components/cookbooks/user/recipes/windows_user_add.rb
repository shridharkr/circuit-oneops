username = node[:user][:username]
ssh_keys = JSON.parse(node[:user][:authorized_keys])

params = "-userName '#{username}' "
if !ssh_keys.empty?
    params += "-sshKeys '#{ssh_keys.shift}'"
    ssh_keys.each do |key|
      params += ", '#{key}'"
    end
end

add_user_script = "#{Chef::Config[:file_cache_path]}/cookbooks/User/files/default/add_user.ps1"
Chef::Log.info("Script path: #{add_user_script}")
cmd = "#{add_user_script} #{params}"
Chef::Log.info("cmd: #{cmd}")

powershell_script "run add_user script" do
  code cmd
end
