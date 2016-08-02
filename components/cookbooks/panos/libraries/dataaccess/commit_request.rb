require File.expand_path('../../models/key.rb', __FILE__)
require File.expand_path('../../models/panos_job.rb', __FILE__)

class CommitRequest

  def initialize(url, key)
    fail ArgumentError, 'url cannot be nil' if url.nil?
    fail ArgumentError, 'key cannot be nil' if key.nil?
    fail ArgumentError, 'key must be of type Key' if !key.is_a? Key

    @baseurl = url
    @key = key
  end

  def commit_configs
    begin
    	commit_response = RestClient::Request.execute(
    		:method => :post,
    		:verify_ssl => false,
    		:url => @baseurl,
    		:headers => {
    			:params => {
    				:key => @key.value,
    				:type => 'commit',
    				:cmd => '<commit></commit>'
    			}
    		}
    	)
      commit_hash = Crack::XML.parse(commit_response)
      Chef::Log.info("commit_hash is: #{commit_hash}")
      raise Exception.new("PANOS Error committing: #{commit_hash['response']['msg']}") if commit_hash['response']['status'] == 'error'
      job = PanosJob.new(commit_hash['response']['result']['job'].to_i)
      Chef::Log.info("PANOS Jobid is: #{job}")
      return job
    rescue => e
      raise Exception.new("Exception committing PANOS job: #{e}")
    end
  end

end
