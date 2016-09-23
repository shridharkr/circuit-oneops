require 'net/smtp'
require "carrier-pigeon"

class IrcHandler < Chef::Handler
  attr_reader :options
  def initialize(opts = {})
    @options = {
        #:to_address => "owain.perry@thetrainline.com"        
        #:template_path => File.join(File.dirname(__FILE__), "mail.erb")
    }
    @options.merge! opts
  end

def report
  status = success? ? "Successful" : "Failed"
  subject = " #{status} chef run took: (#{run_status.elapsed_time})"  
  send_message = "not set"
  if(success?)    
    send_message = "#{subject} \"ok\""
  else
    message = "Start: #{run_status.start_time} End:#{run_status.end_time} (#{run_status.formatted_exception}) \n"
    message << Array(backtrace).join("\n")
    send_message = "#{subject} \"#{message}\""
  end 
  
  CarrierPigeon.send(
    :uri => "irc://#{node.hostname}@irc.ttldev:6667/#chef",
    :message => send_message
  )
  end
end