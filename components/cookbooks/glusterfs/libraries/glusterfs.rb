def find_bricks(index,replicas,length)
  bricks = []
  for n in 0..(replicas-1)
    brick_id = (index - 1) * replicas + 1 - n * (replicas - 1)
    brick_id = brick_id > 0 ? brick_id : brick_id + length * replicas
    bricks << brick_id
  end
  return bricks
end

def check_environment_availability(environment)
  case environment
  when "single"
    return "single"
  when "redundant"
    return "redundant"
  end
end
