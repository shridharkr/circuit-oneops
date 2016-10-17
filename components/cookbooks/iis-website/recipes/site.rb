
site = node["iis-website"]
app_pool_name = site.app_pool_name
runtime_version = site.runtime_version
identity_type = site.identity_type

site_name = site.site_name
binding_type = site.binding_type
binding_port = site.binding_port
physical_path = site.physical_path

site_bindings = [{'protocol' => "#{binding_type}", 'binding_information' => "*:#{binding_port}:"}]

website_physical_path = ::File.join(physical_path, site_name)

directory physical_path do
  recursive true
end

iis_app_pool app_pool_name do
  managed_runtime_version runtime_version
  process_model_identity_type identity_type
  action [:create, :update]
end

iis_web_site site_name do
  bindings site_bindings
  virtual_directory_physical_path website_physical_path.gsub('/', '\\')
  application_pool app_pool_name
  action [:create, :update]
end
