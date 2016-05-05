log_level :info
log_location STDOUT
print_after true
admin false
node_name 'oneops'
register 'oneops'
version '1.0.0'
nspath '/public'
useversion 'true'
client_key 'client_key.pem'
validation_client_name 'chef-validator'
validation_key 'validation.pem'
chef_server_url 'http://localhost:4000'
cache_type 'BasicFile'
cache_options( :path => '.chef/checksums' )
cookbook_path [ 'components/cookbooks' ]
publish_path 'pkgs'
pack_path [ 'packs' ]
service_path [ 'services' ]
cloud_path [ 'clouds' ]
catalog_path [ 'catalogs' ]
default_impl 'oo::chef-11.18.12'