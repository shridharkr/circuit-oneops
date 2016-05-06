
# retrieving data
database_name = JSON.parse(node.workorder.arglist)["database_name"]
snapshot_directory = JSON.parse(node.workorder.arglist)["snapshot_directory"]
snapshot_name = JSON.parse(node.workorder.arglist)["snapshot_name"]

# exiting if data is empty
if database_name.empty? || snapshot_directory.empty? || snapshot_name.empty?
	exit_with_error "database name, snapshot directory or snapshot name cannot be empty"
end

if !File.exists?("#{snapshot_directory}/#{snapshot_name}")
	exit_with_error "unable to find snapshot #{snapshot_name} at #{snapshot_directory}"
end

# checking if database exists
check_if_database_exists database_name

# restoring database from snapshot
restore_db_from_snapshot database_name, snapshot_directory, snapshot_name