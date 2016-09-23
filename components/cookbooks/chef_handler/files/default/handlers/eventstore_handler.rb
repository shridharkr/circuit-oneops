require 'rubygems'
require 'chef'
require 'chef/handler'
require 'erubis'

class EventStoreHandler < Chef::Handler
  attr_reader :options
  def initialize(opts = {})
    @options = {
      :template_path => File.join(File.dirname(__FILE__), "templates/event.erb")
    }
    @options.merge! opts
  end

  def report
      status = success? ? "Successful" : "Failed"
      Chef::Log.info("EventStoreHandler starting")
      Chef::Log.debug("eventstore handler template path: #{options[:template_path]}")
      if File.exists? options[:template_path]
        template = IO.read(options[:template_path]).chomp
      else
        Chef::Log.error("eventstore handler template not found: #{options[:template_path]}")
        raise Errno::ENOENT
      end

      context = {
        :event_id => SecureRandom.uuid,
        :status => status,
        :run_status => run_status
      }

      body = Erubis::EscapedEruby.new(template).evaluate(context)
      Chef::Log.debug("eventstore event: #{body}")

      if Chef::Config[:solo]
        Chef::Log.info("Pretending to send to eventstore: #{body}")
      end

      unless Chef::Config[:solo]
        require 'net/http'

        uri = URI.parse("http://tl-evntstor-001.bti.local/streams/chef-run")
        #uri = URI.parse("http://10.41.9.137/streams/chef-run")
        http = Net::HTTP.new(uri.host, uri.port)
        req = Net::HTTP::Post.new(uri.path)
        req.body = body
        req["Content-Type"] = "application/json"
        response = http.request(req)
        Chef::Log.info("EventStoreHandler finished with EventStore response #{response}")
      end
  end
end