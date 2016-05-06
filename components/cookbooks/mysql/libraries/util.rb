
def exit_with_error(msg)
	Chef::Log.error(msg)
	puts "***FAULT:FATAL=#{msg}"
	Chef::Application.fatal!(msg)
end

def check_if_database_exists(database_name)
	Chef::Log.info("checking if #{database_name} database exists")
	output = `mysql -e 'use #{database_name}' 2>&1`
	exit_with_error "unable to find #{database_name}. #{output}" if $?.exitstatus != 0
	Chef::Log.info("successfully able to find database. #{output}")
end

def create_db_snapshot(database_name, snapshot_directory, snapshot_name)
	`mkdir -p #{snapshot_directory}`
	Chef::Log.info("creating snapshot #{snapshot_name} of database #{database_name} at #{snapshot_directory} ")
	output = `mysqldump #{database_name} 2>&1 > #{snapshot_directory}/#{snapshot_name}`
	exit_with_error "unable to create snapshot. #{output}" if $?.exitstatus != 0
	Chef::Log.info("successfully able to create snapshot. #{output}")
end

def restore_db_from_snapshot(database_name, snapshot_directory, snapshot_name)
	Chef::Log.info("restoring #{database_name} database from snapshot #{snapshot_directory}/#{snapshot_name}")
	output = `mysql --one-database #{database_name} < #{snapshot_directory}/#{snapshot_name}`
	exit_with_error "unable to restore from snapshot. #{output}" if $?.exitstatus != 0
	Chef::Log.info("successfully able to restore from snapshot. #{output}")
end
