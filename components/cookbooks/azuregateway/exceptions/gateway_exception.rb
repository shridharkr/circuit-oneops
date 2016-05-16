class GatewayException < Exception
  def initialize(msg)
    super(:message => msg)
    self.set_backtrace('')
  end
end