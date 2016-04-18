module OOLog
  def fatal(msg)
    Chef::Log.error(msg)
    puts "***FAULT:FATAL=#{msg}"
    ex = Exception.new('no backtrace')
    e.set_backtrace('')
    raise ex
  end

  def info(msg)
    Chef::Log.info(msg)
  end

  def debug(msg)
    Chef::Log.debug(msg)
  end

  module_function :fatal, :info, :debug
end
