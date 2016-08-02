require File.expand_path('../../models/key.rb', __FILE__)
require File.expand_path('../../models/status.rb', __FILE__)

class StatusRequest

  def initialize(url, key)
    fail ArgumentError, 'url cannot be nil' if url.nil?
    fail ArgumentError, 'key cannot be nil' if key.nil?
    fail ArgumentError, 'key must be of type Key' if !key.is_a? Key

    @baseurl = url
    @key = key
  end

  def get_status(jobid)
    begin
      status_response = RestClient::Request.execute(
        :method => :post,
        :verify_ssl => false,
        :url => @baseurl,
        :headers => {
          :params => {
            :key => @key.value,
            :type => 'op',
            :cmd => "<show><jobs><id>#{jobid}</id></jobs></show>"
          }
        }
      )
      status_hash = Crack::XML.parse(status_response)
      Chef::Log.info("status hash is: #{status_hash}")
      raise Exception.new("PANOS Error getting status: #{status_hash['response']['msg']}") if status_hash['response']['status'] == 'error'
      job = status_hash['response']['result']['job']

      message = job['details'].nil? ? nil : job['details']['line']

      status = Status.new(job['status'], job['result'], job['progress'].to_i, message)
      return status
    rescue => e
      raise Exception.new("Exception getting job status: #{e}")
    end
  end

  def job_complete?(job)
    fail ArgumentError, 'job must be of type PanosJob' if !job.is_a? PanosJob
    status = get_status(job.id)
    if status.status == 'FIN' && status.progress == 100
      if status.result == 'OK'
        return true
      else
        raise Exception.new("Job completed but failed: #{status}")
      end
    else
      return false
    end
  end

end
