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

case node.kubernetes.network
when 'flannel'

  # install flannel
  package 'flannel'
  template '/etc/sysconfig/flanneld' do
    source 'flanneld.erb'
  end

  service 'flanneld' do
    action [:enable, :restart]
  end      

  network_cidr = "11.11.0.0/16"
  if node.workorder.payLoad.has_key?("manifest-docker")
    docker = node.workorder.payLoad['manifest-docker'].first
    network_cidr = docker['ciAttributes']['network_cidr']
  end
      
  execute "etcdctl mk /atomic.io/network/config '{\"Network\":\"#{network_cidr}\"}'" 
  #execute "etcdctl mk /atomic.io/network/config '{\"Network\": \"#{network_cidr}\", \"SubnetLen\": 24, \"Backend\": {\"Type\": \"vxlan\", \"VNI\": 1}}'"

  if node.workorder.payLoad.has_key?("manifest-docker")
    docker = node.workorder.payLoad['manifest-docker'].first
    ci_index = node.workorder.rfcCi.ciName.split('-').last  
    if ci_index.to_i == 1    
      network_cidr = docker['ciAttributes']['network_cidr']
      Chef::Log.info("setting etcd flannel network: #{network_cidr}")
      
    end
  end

end


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


# generate kubernetes config file
%w(apiserver config controller-manager scheduler).each do |file|
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
%w(kube-apiserver.service kube-controller-manager.service kube-scheduler.service).each do |service|
  cookbook_file "/usr/lib/systemd/system/#{service}" do
    source service
    mode 00644
    action :create
  end
end

# define kubernetes master services
%w(kube-apiserver kube-controller-manager kube-scheduler).each do |service|
  service service do
    action [:enable, :restart]
  end
end
