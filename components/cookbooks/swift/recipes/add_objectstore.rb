platform = node[:swift][:platform]
platform['swift_client_packages'].each do |pkg|
  package pkg do
    options platform['override_options']

    action :upgrade
  end
end

template node[:swift][:homepath] + '/openrc' do
  source 'openrc.erb'
  mode 644
  action :create
end
