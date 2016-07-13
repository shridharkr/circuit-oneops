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

# kubernetes master
default['kube']['api']['host'] = ''
default['kube']['api']['bind-address'] = '0.0.0.0'
default['kube']['api']['bind-port'] = '8080'
default['kube']['api']['args'] = ''
default['kube']['service']['addresses'] = '10.254.0.0/16'
default['kube']['controller-manager']['args'] = ''
default['kube']['scheduler']['args'] = ''

# kubernetes minions
default['kube']['kubelet']['machines'] = []
default['kube']['kubelet']['bind-address'] = '0.0.0.0'
default['kube']['kubelet']['bind-port'] = '10250'
default['kube']['kubelet']['args'] = ''
default['kube']['proxy']['args'] = ''

default['kube']['interface'] = 'eth0'

mirror = "https://github.com/GoogleCloudPlatform"
cloud_name = node.workorder.cloud.ciName
if node.workorder.services.has_key?("mirror") &&
   node.workorder.services.mirror[cloud_name]['ciAttributes']['mirrors'].include?('kubernetes')
  
  mirrors = JSON.parse(node.workorder.services.mirror[cloud_name]['ciAttributes']['mirrors'])
  if mirrors.has_key?("kubernetes")
    mirror = mirrors['kubernetes']    
    Chef::Log.info("using mirrors payload: #{mirror}")
  end
  
end
default['kube']['package'] = mirror+"/kubernetes/releases/download/v#{node.workorder.rfcCi.ciAttributes.version}/kubernetes.tar.gz"

# related packages
default['kube']['go']['package'] = 'golang'
