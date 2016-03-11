module OOLog
  def fatal(msg)
    Chef::Log.error(msg)
    puts "***FAULT:FATAL=#{msg}"
    raise msg
  end
  module_function :fatal
end
