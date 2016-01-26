dbname = node.database.dbname
username = node.database.username
password = node.database.password
extra = ""
if node.database.has_key?("extra") 
  extra = node.database.extra
end

Chef::Log.info("Using database #{dbname} with user #{username}")

bash "createdb" do
  code <<-EOH
    /usr/bin/mysql -u root -e 'CREATE DATABASE #{dbname};'
  EOH
  not_if "/usr/bin/mysql -u root -D #{dbname} -e status"
end

bash "createuser" do
  code <<-EOH
    /usr/bin/mysql -u root -e 'GRANT ALL PRIVILEGES ON #{dbname}.* TO "#{username}"@"%" IDENTIFIED BY "#{password}"; FLUSH PRIVILEGES;'
  EOH
end

file "/tmp/#{dbname}_extra.sql" do
  content "#{extra}"
end

bash "run extra" do
  code <<-EOH
    /usr/bin/mysql -u root -D #{dbname} < /tmp/#{dbname}_extra.sql
  EOH
end