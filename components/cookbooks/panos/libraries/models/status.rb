class Status

  attr_reader :status, :result, :progress, :message

  def initialize(status, result, progress, message = nil)
    fail ArgumentError, 'status cannot be nil' if status.nil?
    fail ArgumentError, 'result cannot be nil' if result.nil?
    fail ArgumentError, 'progress cannot be nil' if progress.nil?
    fail ArgumentError, 'progress must be an Integer' if !progress.is_a? Integer

    super()
    @status = status
    @result = result
    @progress = progress
    @message = message
  end

end
