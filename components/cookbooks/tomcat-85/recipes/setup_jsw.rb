###############################################################################
# Cookbook Name:: tomcat_8-5
# Recipe:: add_repo
# Purpose:: This recipe is used to do the initial setup of the Tomcat system
#     settings before the Tomcat binaries are installed onto the server.
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
###############################################################################
jsw_install_root_dir = node['tomcat']['install_root_dir']
jsw_server_user = node['tomcat']['server_user']
jsw_server_group = node['tomcat']['server_group']

###############################################################################
###############################################################################
node.set['javaservicewrapper']['url'] = 'http://gec-maven-nexus.walmart.com/nexus/content/groups/public/org/rzo/yajsw/stable-11.08/yajsw-stable-11.08.zip'
node.set['javaservicewrapper']['install_dir'] = "#{jsw_install_root_dir}"
node.set['javaservicewrapper']['app_title'] = "enterprise-server"
node.set['javaservicewrapper']['start_main_args'] = "[]"
node.set['javaservicewrapper']['environment_vars'] = "[]"
node.set['javaservicewrapper']['main_class'] = "org.apache.catalina.startup.Bootstrap"
node.set['javaservicewrapper']['working_dir'] = "#{jsw_install_root_dir}/enterprise-server"
node.set['javaservicewrapper']['java_classpath_params'] = '["./bin/bootstrap.jar", "./bin/tomcat-juli.jar"]'
node.set['javaservicewrapper']['java_params'] = '["-Djava.util.logging.config.file=./conf/logging.properties","-Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager","-javaagent:./lib/openejb-javaagent.jar","-Djava.endorsed.dirs=./endorsed","-Dcatalina.base=./","-Dcatalina.home=./","-Djava.io.tmpdir=./temp"]'
node.set['javaservicewrapper']['as_user'] = "#{jsw_server_user}"
node.set['javaservicewrapper']['as_group'] = "#{jsw_server_group}"
