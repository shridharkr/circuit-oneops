if node[:workorder][:rfcCi][:ciAttributes][:ostype] =~ /windows/
  username = node[:user][:username]
  ssh_keys = JSON.parse(node[:user][:authorized_keys])

  params = "-userName '#{username}' "
  if !ssh_keys.empty?
      params += "-sshKeys '#{ssh_keys.shift}'"
      ssh_keys.each do |key|
        params += ", '#{key}'"
      end
  end

  add_user_script = "#{Chef::Config[:file_cache_path]}/cookbooks/user/files/default/add_user.ps1"
  Chef::Log.info("Script path: #{add_user_script}")
  cmd = "#{add_user_script} #{params}"
  Chef::Log.info("cmd: #{cmd}")

  powershell_script "run add_user script" do
    code cmd
  end

else
  home_dir = node[:user][:home_directory]
  node.set[:user][:home] = home_dir && !home_dir.empty? ? home_dir : "/home/#{node[:user][:username]}"

  Chef::Log.info("Stopping the nslcd service")
  `sudo killall -9  /usr/sbin/nslcd`

  user "#{node[:user][:username]}" do
    comment node[:user][:description]
    supports :manage_home => true
    home node[:user][:home]
    if node[:user][:system_user] == 'true'
      system true
      shell '/bin/false'
    else
      shell node[:user][:login_shell] unless node[:user][:login_shell].empty?
    end
  end

  group "#{node[:user][:username]}"


  username = node[:user][:username]

  directory "#{node[:user][:home]}" do
    owner node[:user][:username]
    group node[:user][:username]
  end

  directory "#{node[:user][:home]}/.ssh" do
    owner node[:user][:username]
    group node[:user][:username]
    mode 0700
  end

  if node[:user].has_key?("home_directory_mode")
    execute "chmod #{node[:user][:home_directory_mode]} #{node[:user][:home]}"
  end

  file "#{node[:user][:home]}/.ssh/authorized_keys" do
    owner node[:user][:username]
    group node[:user][:username]
    mode 0600
    content JSON.parse(node[:user][:authorized_keys]).join("\n")
  end

  if node[:user][:sudoer] == 'true'
    Chef::Log.info("adding #{username} to sudoers.d")
    `echo "#{username} ALL = (ALL) NOPASSWD: ALL" > /etc/sudoers.d/#{username}`
    `chmod 440 /etc/sudoers.d/#{username}`
  else
    `rm -f /etc/sudoers.d/#{username}`
  end

  # workaround for docker containers
  docker = system 'test -f /.dockerinit'

  if !docker
    ulimit = node[:user][:ulimit]
    if (!ulimit.nil?)
      Chef::Log.info("Setting ulimit to " + ulimit)
       `grep -E "^#{username} soft nofile" /etc/security/limits.conf`
       if $?.to_i == 0
        Chef::Log.info("ulimit already present for #{username} in the file /etc/security/limits.conf")
        `sed -i '/#{username}/d' /etc/security/limits.conf`
       end
        Chef::Log.info("adding ulimit for #{username}")
        `echo "#{username} soft nofile #{ulimit}" >> /etc/security/limits.conf`
        `echo "#{username} hard nofile #{ulimit}" >> /etc/security/limits.conf`

    else
    	Chef::Log.info("ulimit attribute not found. Not writing to the limits.conf")
    end
  else
    Chef::Log.info("changing limits.conf not supported on containers")
  end
end
