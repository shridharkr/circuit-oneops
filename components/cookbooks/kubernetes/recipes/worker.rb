# encoding: UTF-8
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'kubernetes::firewall'
include_recipe 'kubernetes::go'
include_recipe 'kubernetes::install'

kubelet_args_value = ''
if node.kubernetes.has_key?("kubelet_args")
  kubelet_args = JSON.parse(node.kubernetes.kubelet_args)
  kubelet_args.each_pair do |k,v|
    Chef::Log.info("setting kubelet arg: --#{k}=#{v}")
    kubelet_args_value += " --#{k}=#{v}"
  end
end
node.set['kube']['kubelet']['args'] = kubelet_args_value
  
proxy_args_value = ''
if node.kubernetes.has_key?("proxy_args")
  proxy_args = JSON.parse(node.kubernetes.proxy_args)
  proxy_args.each_pair do |k,v|
    Chef::Log.info("setting proxy arg: --#{k}=#{v}")
    proxy_args_value += " --#{k}=#{v}"
  end
end
node.set['kube']['proxy']['args'] = proxy_args_value  

# generate kubernetes config file
%w(config kubelet proxy).each do |file|
  template "/etc/kubernetes/#{file}" do
    cookbook 'kubernetes'
    source "#{file}.erb"
    owner 'root'
    group 'root'
    mode 00644
    action :create
  end
end

# generate systemd file
%w(kubelet.service kube-proxy.service).each do |service|
  cookbook_file "/usr/lib/systemd/system/#{service}" do
    source service
    mode 00644
    action :create
  end
end

# define kubernetes master services
%w(kubelet kube-proxy).each do |service|
  service service do
    action [:enable, :restart]
  end
end
