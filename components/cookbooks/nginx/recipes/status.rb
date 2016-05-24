#
# Cookbook Name:: nginx
# Recipe:: status

cmd = Mixlib::ShellOut.new("service nginx status")
cmd.run_command
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
