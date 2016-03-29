# Cookbook Name:: topic
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

amq = node.workorder.payLoad[:activemq][0]
appresourcename = "#{node['topic']['topicname']}"
activemq_home = "#{amq[:ciAttributes][:installpath]}/activemq"

execute "delete ActiveMQ Topic" do
  cwd "#{amq[:ciAttributes][:installpath]}/activemq"
  command "java -cp 'amq-messaging-resource.jar:*' io.strati.amq.MessagingResources -s 'localhost' -r deletetopic -dn #{appresourcename}"
  cmd = Mixlib::ShellOut.new(command).run_command
    if cmd.stdout.include? "Error"
       Chef::Log.error("Error occurred : #{cmd.stdout}")
      exit 1
    else
      Chef::Log.info("Execution completed: #{cmd.stdout}")
    end
  only_if { node.topic.destinationtype.strip.to_s != 'T' }
end

execute "delete destination" do
   command "sed -i /#{node['topic']['destinationtype']}-#{appresourcename}-#{node['topic']['destinationtype']}/d #{activemq_home}/conf/activemq.xml"
end