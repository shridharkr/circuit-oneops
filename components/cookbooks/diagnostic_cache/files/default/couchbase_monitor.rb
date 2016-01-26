require 'json'
require 'net/http'
require 'socket'
require 'logger'

class CouchbaseMonitor

  attr_accessor :hostname, :prefix, :username, :password, :graphite_hosts,
                :environment, :cloudname, :tcp_sockets,
                :graphite_logfiles_path, :rotate,  :log_size,
                :logger, :healthy_nodes, :failover_nodes


  CONST_CLUSTER_LEVEL = 1
  CONST_NODE_LEVEL = 2
  CONST_BUCKET_LEVEL = 3
  CONST_MAX_LOG_FILE_ROTATION_DAYS = 10
  CONST_MAX_LOG_FILE_SIZE = 10 * 1024 * 1024

  #Constructor to initialize this class with input parameters
  def initialize(hostname, user, password, graphite_hosts,
                 prefix, env, cloud,
                 graphite_logfiles_path, rotate,  log_size)

    @hostname = "http://#{hostname}"
    @username = user
    @password = password
    @graphite_hosts = graphite_hosts
    @prefix = prefix
    @environment = env
    @cloudname = cloud
    @graphite_logfiles_path = graphite_logfiles_path

    #Use defaults if log file rotation isn't set up
    if (rotate == nil || rotate == 0)
      rotate = CONST_MAX_LOG_FILE_ROTATION_DAYS
    end
    @rotate = rotate

    #Use defaults if log file size isn't set up
    if (log_size == nil || log_size == 0)
      log_size =  CONST_MAX_LOG_FILE_SIZE
    end
    @log_size = log_size
    @logger = Logger.new(@graphite_logfiles_path, @rotate,  @log_size)
    @healthy_nodes = 0
    @failover_nodes = 0

    # Setting logging level to Error for the initial version. The plan
    # is to accept it as an incoming parameter in the future.
    logger.level = Logger::ERROR
  end

  #All REST calls are made through here
  def rest_call(endpoint)
    logger.info "rest_call:start: for endpoint = #{endpoint}"

    uri = URI.parse(endpoint)

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(@username, @password)
    response = http.request(request)
    logger.info 'rest_call:end: Completed'

    return response.body

  end

  #Opens tcp sockets to all graphite servers on the specified port#
  def open_tcp_sockets()
    logger.info "open_tcp_sockets:start: graphite host list = #{@graphite_hosts}"

    if (@graphite_hosts.length > 0)

      @tcp_sockets = Array.new
      graphite_hosts.each do |graphite_host|
        begin
          graphite_server = graphite_host.split(':')[0]
          port = graphite_host.split(':')[1]
          tcp_socket = TCPSocket.new(graphite_server, port)
          @tcp_sockets.insert(-1, tcp_socket)
        rescue Exception => e
          logger.error "open_tcp_sockets:exception: graphite host = #{graphite_host} #{e}"
        end
      end

    end

    logger.info 'open_tcp_sockets:end: Completed'

  end


  #Close tcp sockets to all graphite servers
  def close_tcp_sockets()
    logger.info "close_tcp_sockets:start: tcp sockets list = #{@tcp_sockets}"

    if (@tcp_sockets.length > 0)

      @tcp_sockets.each do |tcp_socket|
        begin
          tcp_socket.close
        rescue Exception => e
          logger.error "close_tcp_sockets:exception: #{e}"
        end
      end

    end

    logger.info 'close_tcp_sockets:end: Completed'

  end


  #Iterates through a list of graphite hosts, opens up a TCP connection and
  #writes the metrics out to the graphite server
  def write_to_graphite(key, value, time = Time.now)
    logger.info "write_to_graphite:start: key = #{key}, value = #{value}, time = #{time.to_i}"

    if (@tcp_sockets.length > 0)

      @tcp_sockets.each do |tcp_socket|

        begin
          tcp_socket.write("#{key} #{value.to_f} #{time.to_i}\n")
          #puts key, value, time.to_i
        rescue Exception => e
          logger.error "write_to_graphite:exception: #{e}"
        end
      end

    end
    logger.info 'write_to_graphite:end: Completed'

  end


  def basic_check(url)
    logger.info "basic_check:start: url = #{url}"
    jsonResponse = rest_call(url)
    myHash = JSON.parse(jsonResponse)
    puts myHash["isAdminCreds"]
    puts myHash["settings"]["maxParallelIndexers"]
    puts myHash["componentsVersion"]["ns_server"]
    logger.info 'basic_check:end: Completed'
  end


  #Construct the metric name
  #May be cluster level (1), node level (2) or bucket level (3)
  def construct_metric_name(metric_name, level)
    logger.info "construct_metric_name:start: metric_name = #{metric_name}, level = #{level}"
    # The logic for adding 'DF.' is going to be the responsiblility of the cron job
    # invoking this ruby script. That way the caller is aware of the
    final_metric_name = "#{@prefix}.#{@environment}.cache.#{@cloudname}."

    case level
      when CONST_CLUSTER_LEVEL
        final_metric_name += metric_name
      when CONST_NODE_LEVEL
        final_metric_name += 'nodes'.concat('.').concat( metric_name)
      when CONST_BUCKET_LEVEL
        final_metric_name += 'buckets'.concat('.').concat( metric_name)
    end
    logger.info "construct_metric_name:end: final_metric_name = #{final_metric_name}"

    return final_metric_name
  end


  #Gather cluster statistics and stream it to the graphite servers
  def cluster_stats(url, time)

    logger.info "cluster_stats:start: url = #{url}, time = #{time.to_i}"

    jsonResponse = rest_call(url)
    response_hash = JSON.parse(jsonResponse)
    #puts response_hash
    node_count = response_hash['nodes'].count
    nodes = response_hash['nodes']

    #puts "Total number of nodes in the cluster = #{node_count.to_s}"

    #rebalance status in the cluster
    rebalanceStatus = response_hash['rebalanceStatus']
    rebalance = rebalanceStatus.eql?('none') ? 0 : 1

    #ram metrics in the cluster
    ram_total = response_hash['storageTotals']['ram']['total']
    ram_quota_total = response_hash['storageTotals']['ram']['quotaTotal']
    ram_quota_used = response_hash['storageTotals']['ram']['quotaUsed']
    ram_used = response_hash['storageTotals']['ram']['used']
    ram_used_by_data = response_hash['storageTotals']['ram']['usedByData']
    ram_quota_used_per_node = response_hash['storageTotals']['ram']['quotaUsedPerNode']
    ram_quota_total_per_node = response_hash['storageTotals']['ram']['quotaTotalPerNode']

    #cluster RAM level stats
    write_to_graphite( construct_metric_name('rebalance', CONST_CLUSTER_LEVEL), rebalance, time)
    write_to_graphite( construct_metric_name('ram_total', CONST_CLUSTER_LEVEL), ram_total.to_s, time)
    write_to_graphite( construct_metric_name('ram_quota_total', CONST_CLUSTER_LEVEL), ram_quota_total.to_s, time)
    write_to_graphite( construct_metric_name('ram_quota_used', CONST_CLUSTER_LEVEL), ram_quota_used.to_s, time)
    write_to_graphite( construct_metric_name('ram_used', CONST_CLUSTER_LEVEL), ram_used.to_s, time)
    write_to_graphite( construct_metric_name('ram_used_by_data', CONST_CLUSTER_LEVEL), ram_used_by_data.to_s, time)
    write_to_graphite( construct_metric_name('ram_quota_used_per_node', CONST_CLUSTER_LEVEL), ram_quota_used_per_node.to_s, time)
    write_to_graphite( construct_metric_name('ram_quota_total_per_node', CONST_CLUSTER_LEVEL), ram_quota_total_per_node.to_s, time)

    #HDD metrics in the cluster
    hdd_total = response_hash['storageTotals']['hdd']['total']
    hdd_quota_total = response_hash['storageTotals']['hdd']['quotaTotal']
    hdd_used = response_hash['storageTotals']['hdd']['used']
    hdd_used_by_data = response_hash['storageTotals']['hdd']['usedByData']
    hdd_free = response_hash['storageTotals']['hdd']['free']

    #cluster HDD level stats
    write_to_graphite( construct_metric_name('hdd_total', CONST_CLUSTER_LEVEL), hdd_total.to_s, time)
    write_to_graphite( construct_metric_name('hdd_quota_total', CONST_CLUSTER_LEVEL), hdd_quota_total.to_s, time)
    write_to_graphite( construct_metric_name('hdd_used', CONST_CLUSTER_LEVEL), hdd_used.to_s, time)
    write_to_graphite( construct_metric_name('hdd_used_by_data', CONST_CLUSTER_LEVEL), hdd_used_by_data.to_s, time)
    write_to_graphite( construct_metric_name('hdd_free', CONST_CLUSTER_LEVEL), hdd_free.to_s, time)

    nodes.each do |node|

      #systemStats
      swap_total = node['systemStats']['swap_total']
      swap_used = node['systemStats']['swap_used']
      mem_total = node['systemStats']['mem_total']
      mem_free = node['systemStats']['mem_free']

      #interestingStats
      cmd_get = node['interestingStats']['cmd_get']
      couch_docs_actual_disk_size = node['interestingStats']['couch_docs_actual_disk_size']
      couch_docs_data_size = node['interestingStats']['couch_docs_data_size']
      curr_items = node['interestingStats']['curr_items']
      curr_items_tot = node['interestingStats']['curr_items_tot']
      ep_bg_fetched = node['interestingStats']['ep_bg_fetched']
      get_hits = node['interestingStats']['get_hits']
      mem_used = node['interestingStats']['mem_used']
      ops = node['interestingStats']['ops']
      vb_replica_curr_items = node['interestingStats']['vb_replica_curr_items']

      clusterMembership = node['clusterMembership']
      status = node['status']
      otpNode = node['otpNode']
      otpNode = otpNode.gsub('.','-')


      if (status =='healthy' && clusterMembership == 'active' )
        @healthy_nodes += 1
      end

      if (clusterMembership == 'inactiveFailed' )
        @failover_nodes += 1
      end

      #node level systemStats
      write_to_graphite( construct_metric_name("#{otpNode}.swap_total", CONST_NODE_LEVEL), swap_total.to_s, time)
      write_to_graphite( construct_metric_name("#{otpNode}.swap_used", CONST_NODE_LEVEL), swap_used.to_s, time)
      write_to_graphite( construct_metric_name("#{otpNode}.mem_total", CONST_NODE_LEVEL), mem_total.to_s, time)
      write_to_graphite( construct_metric_name("#{otpNode}.mem_free", CONST_NODE_LEVEL), mem_free.to_s, time)


      #node level interestingStats
      write_to_graphite( construct_metric_name("#{otpNode}.cmd_get", CONST_NODE_LEVEL), cmd_get, time)
      write_to_graphite( construct_metric_name("#{otpNode}.couch_docs_actual_disk_size", CONST_NODE_LEVEL), couch_docs_actual_disk_size, time)
      write_to_graphite( construct_metric_name("#{otpNode}.couch_docs_data_size", CONST_NODE_LEVEL), couch_docs_data_size, time)
      write_to_graphite( construct_metric_name("#{otpNode}.curr_items", CONST_NODE_LEVEL), curr_items)
      write_to_graphite( construct_metric_name("#{otpNode}.curr_items_tot", CONST_NODE_LEVEL), curr_items_tot, time)
      write_to_graphite( construct_metric_name("#{otpNode}.ep_bg_fetched", CONST_NODE_LEVEL), ep_bg_fetched, time)
      write_to_graphite( construct_metric_name("#{otpNode}.get_hits", CONST_NODE_LEVEL), get_hits, time)
      write_to_graphite( construct_metric_name("#{otpNode}.mem_used", CONST_NODE_LEVEL), mem_used, time)
      write_to_graphite( construct_metric_name("#{otpNode}.ops", CONST_NODE_LEVEL), ops, time)
      write_to_graphite( construct_metric_name("#{otpNode}.vb_replica_curr_items", CONST_NODE_LEVEL), vb_replica_curr_items, time)

    end

    healthy = nodes.length == @healthy_nodes? 1 : 0
    write_to_graphite( construct_metric_name('healthy_node_num', CONST_CLUSTER_LEVEL), @healthy_nodes.to_s, time)
    write_to_graphite( construct_metric_name('node_num', CONST_CLUSTER_LEVEL), nodes.length.to_s, time)
    write_to_graphite( construct_metric_name('healthy', CONST_CLUSTER_LEVEL), healthy.to_s, time)

    logger.info 'cluster_stats:end: Completed'
  end


  #Collects all bucket level metrics from the cluster and stream it to graphite clusters
  def bucket_stats(url, time)

    logger.info "bucket_stats:start: url = #{url}, time = #{time.to_i}"

    jsonResponse = rest_call(url)
    buckets = JSON.parse(jsonResponse)

    buckets.each do |bucket|
      bucket_name = bucket['name']
      replica_num =  bucket['replicaNumber']
      ram_quota = bucket['quota']['ram']
      ram_quota_raw = bucket['quota']['rawRAM']
      quota_percent_used = bucket['basicStats']['quotaPercentUsed']
      ops_per_sec = bucket['basicStats']['opsPerSec']
      disk_fetches = bucket['basicStats']['diskFetches']
      item_count = bucket['basicStats']['itemCount']
      disk_used = bucket['basicStats']['diskUsed']
      data_used = bucket['basicStats']['dataUsed']
      mem_used = bucket['basicStats']['memUsed']
      node_size = bucket['nodes'].length

      data_availability_pct = data_availability(node_size, replica_num, @healthy_nodes, @failover_nodes)

      write_to_graphite( construct_metric_name("#{bucket_name}.replica_num", CONST_BUCKET_LEVEL), replica_num.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.quota_percent_used", CONST_BUCKET_LEVEL), quota_percent_used.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.ops", CONST_BUCKET_LEVEL), ops_per_sec.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.mem_used", CONST_BUCKET_LEVEL), mem_used.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.item_cnt", CONST_BUCKET_LEVEL), item_count.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.disk_used", CONST_BUCKET_LEVEL), disk_used.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.disk_fetches", CONST_BUCKET_LEVEL), disk_fetches.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.data_used", CONST_BUCKET_LEVEL), data_used.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.ram_quota", CONST_BUCKET_LEVEL), ram_quota.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.ram_quota_raw", CONST_BUCKET_LEVEL), ram_quota_raw.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.data_availability_pct", CONST_BUCKET_LEVEL), data_availability_pct.to_s, time)

    end

    logger.info 'bucket_stats:end: Completed'
  end


  #Primary entrance point to collect all metrics from the cluster
  def collect_all_stats()

    begin
      logger.info 'collect_all_stats:start: Starting'
  
      #basic_check_url = 'http://localhost:8091/pools'
      cluster_stats_url = "#{@hostname}/pools/default"
      bucket_stats_url  = "#{@hostname}/pools/default/buckets"
  
      time = Time.now
  
      open_tcp_sockets
  
      #Item Pricing cluster
      #cluster_stats_url  = 'http://10.9.249.152:8091/pools/default'
      cluster_stats(cluster_stats_url, time)
  
      #bucket_stats_url  = 'http://10.9.249.152:8091/pools/default/buckets'
      bucket_stats(bucket_stats_url, time)
  
      close_tcp_sockets
  
      logger.info 'collect_all_stats:end: Completed'
    rescue Exception => e
      logger.error "collect_all_stats:exception: #{e}"
    end
  end


  #Custom formula to compute data availability for a bucket
  def data_availability(node_size, replica_count, healthy_nodes, failover_nodes)

    logger.info "data_availability:start: node_size = #{node_size}, replica_count = #{replica_count},
      healthy_nodes = #{healthy_nodes}, failover_nodes = #{failover_nodes}"

    data_percent_per_node = 1.0 / node_size
    replica_data_percent_per_node = data_percent_per_node * replica_count
    replica_data_percent_per_node_with_failover = 0
    availability = 0

    if (0 < failover_nodes)
        replica_data_percent_per_node_with_failover = replica_data_percent_per_node / (node_size - failover_nodes)
    end

    availability = (data_percent_per_node + replica_data_percent_per_node_with_failover) * healthy_nodes

    if (availability > 1)
        availability = 1
    end
    return_value = "#{'%.2f' % (availability * 100)}"

    logger.info "data_availability:end: return_value = #{return_value}"

    return return_value

  end

end
