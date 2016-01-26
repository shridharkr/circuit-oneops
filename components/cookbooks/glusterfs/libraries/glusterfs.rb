def find_bricks(index,replicas,length)
  bricks = []
  for n in 0..(replicas-1)
    brick_id = (index - 1) * replicas + 1 - n * (replicas - 1)
    brick_id = brick_id > 0 ? brick_id : brick_id + length * replicas
    bricks << brick_id
  end
  return bricks
end

def check_for_error_message(message)
	bad_messages=["fail", "error", "Error"]
	if bad_messages.any? { |m| message.include?(m) }
		return "fail"
	else
		return "success"
	end
end
