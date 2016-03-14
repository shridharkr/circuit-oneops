include_recipe "redisio::default"
include_recipe "redisio::install"
include_recipe "redisio::enable"
include_recipe 'redisio::wire_ci_attr'
