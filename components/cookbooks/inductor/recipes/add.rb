# Copyright 2016, Walmart Stores, Inc.
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

# create answer file
inductor = node.workorder.rfcCi

inductor_name = inductor[:ciName]
inductor_home = inductor[:ciAttributes][:inductor_home]

# cert
directory "#{inductor_home}/certs"
file "#{inductor_home}/certs/#{inductor_name}" do
  content inductor[:ciAttributes][:cert]
end

# cert for perf-agents
file "#{inductor_home}/certs/perf_collector_cert.crt" do
  content inductor[:ciAttributes][:perf_collector_cert]
end

# answers
# TODO metrics is hard-coded to true because collector_domain is needed for logs, conditional question should be removed
directory "#{inductor_home}/answers"
file "#{inductor_home}/answers/#{inductor_name}" do
  content <<-EOT
#{inductor[:ciAttributes][:mqhost]}
#{inductor[:ciAttributes][:dns]}
#{inductor[:ciAttributes][:debug]}
true
#{inductor[:ciAttributes][:collector_domain]}
#{inductor_home}/certs/perf_collector_cert.crt
#{inductor[:ciAttributes][:ip]}
#{inductor[:ciAttributes][:queue]}
#{inductor[:ciAttributes][:url]}
#{inductor_home}/certs/#{inductor_name}
#{inductor[:ciAttributes][:logstash_hosts]}
#{inductor[:ciAttributes][:max]}
#{inductor[:ciAttributes][:maxlocal]}
#{inductor[:ciAttributes][:authkey]}
#{inductor[:ciAttributes][:additional_java_args]}
#{inductor[:ciAttributes][:env_vars]}
EOT
end

# add/update inductor queue
execute "inductor add < #{inductor_home}/answers/#{inductor_name}" do
  cwd inductor_home
end

# this needs to be fixed in the gem
execute "chmod +x #{inductor_home}/clouds-available/*/bin/*"
