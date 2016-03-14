# Cookbook Name:: docker_engine
# Attributes:: add_docker_gem
#
# Install docker remote API gem
#
# Author : OneOps
# Apache License, Version 2.0


# Install docker remote API client
docker_api_gem = 'docker-api-1.26.2.gem'
gem_file = "/tmp/#{docker_api_gem}"

cookbook_file gem_file do
  source docker_api_gem
  owner 'root'
  group 'root'
  mode 0755
end

gem_package 'docker-api' do
  source gem_file
  options ('--no-ri  --no-rdoc')
  action :install
end