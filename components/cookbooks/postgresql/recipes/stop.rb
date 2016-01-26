#
# Cookbook Name:: postgresql
# Recipe:: stop

service "postgresql-9.1" do
    pattern "postgres: writer"
    action :stop
end
