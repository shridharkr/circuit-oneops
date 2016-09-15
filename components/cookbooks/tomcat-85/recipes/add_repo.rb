# rubocop:disable LineLength
###############################################################################
# Cookbook Name:: tomcat_8-5
# Recipe:: add_repo
# Purpose:: This recipe is used to install the Tomcat binaries onto the server.
#
# Copyright 2010, Opscode, Inc.
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
###############################################################################

###############################################################################
# Setup Base Directory
#   '%w' creates an array with "run, source, software, and build"
#   In the '#{node.tomcat.base}/#{dir}' directory, each of these objects is
#     created recursively.
###############################################################################
%w(run source software build).each do |dir|
  Chef::Log.warn("creating #{node.tomcat.base}/#{dir}")
  directory "#{node.tomcat.base}/#{dir}" do
    mode 0775
    action :create
    recursive true
  end
end

###############################################################################
# Tomcat Download
#   This installed the Tomcat binaries from the repo specified in the cloud's
#   Mirror.
#   1 - Create listof package names based on OS
#   2 - Clean up metadata if OS = rhel
#   3 - If OS is not fedora|redhat|centos, OneOps will check for a lock file.
#     OneOps will retry until lock is gone of it hits 20 retries.
#     Package will install on fedora|redhat|centos and on other OSs once lock
#       is gone.
###############################################################################
if platform_family?('rhel')
  execute 'yum clean metadata' do
    user 'root'
    group 'root'
  end
end

package "tomcat-8" do
  version "v" + node['tomcat']['tomcat_version_name']
end

###############################################################################
# End of add_repo.rb
###############################################################################
