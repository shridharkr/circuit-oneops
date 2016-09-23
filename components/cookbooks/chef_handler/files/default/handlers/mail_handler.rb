require 'rubygems'
require 'chef'
require 'chef/handler'
require 'erubis'
require 'pony'

class MailHandler < Chef::Handler
  attr_reader :options
  def initialize(opts = {})
    @options = {
      :to_address => "root",
      :template_path => File.join(File.dirname(__FILE__), "templates/mail.erb")
    }
    @options.merge! opts
  end

  def report
    unless success?
      status = success? ? "Successful" : "Failed"
      subject = "#{status} Chef run on node #{node.fqdn}"

      Chef::Log.debug("mail handler template path: #{options[:template_path]}")
      if File.exists? options[:template_path]
        template = IO.read(options[:template_path]).chomp
      else
        Chef::Log.error("mail handler template not found: #{options[:template_path]}")
        raise Errno::ENOENT
      end

      context = {
        :status => status,
        :run_status => run_status
      }

      body = Erubis::Eruby.new(template).evaluate(context)

      Pony.mail(
        :to => options[:to_address],
        :from => "chef-client@#{node.fqdn}",
        :subject => subject,
        :body => body,
        :via => :smtp,
        :via_options => {
          :address        => 'EXC-FE1.thetrainline.com'
        }
      )
    end
  end
end