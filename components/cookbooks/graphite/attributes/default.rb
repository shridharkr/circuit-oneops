#
# Cookbook Name:: graphite
# Attributes:: default
#

default['graphite']['version'] = "0.9.15"

default['graphite']['install_path'] = "/opt/graphite"
default['graphite']['replication_factor'] = "1"

default['graphite']['download_base_url'] = "https://github.com/graphite-project/"

default['graphite']['account']['user'] = "graphite"
default['graphite']['account']['group'] = "graphite"
default['graphite']['dir']['log_dir'] = "/var/log/graphite"
default['graphite']['dir']['whisper_dir'] = "/opt/graphite/storage/whisper"
