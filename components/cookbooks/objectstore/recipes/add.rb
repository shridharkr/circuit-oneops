cloud_name = node[:workorder][:cloud][:ciName]
cloud_type = node[:workorder][:services][:filestore][cloud_name][:ciClassName].split(".").last.downcase


case cloud_type
when /swift/
  include_recipe "swift::add_objectstore"
end

cookbook_file "objectstore" do
  mode "755"
  path "/usr/local/bin/objectstore"
end
