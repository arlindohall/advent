
Step = Struct.new(:text)
class Step
  def distance
    text.chars.drop(1).join.to_i
  end

  def turn
    text.chars.first
  end

  def direction(current_direction)
    case current_direction
    when 'N'
      turn == 'R' ? 'E' : 'W'
    when 'S'
      turn == 'R' ? 'W' : 'E'
    when 'E'
      turn == 'R' ? 'S' : 'N'
    when 'W'
      turn == 'R' ? 'N' : 'S'
    end
  end
end

Walker = Struct.new(:x, :y, :direction)
class Walker
  def step(step)
    case step.direction(direction)
    when 'N'
      self.y += step.distance
    when 'S'
      self.y -= step.distance
    when 'E'
      self.x += step.distance
    when 'W'
      self.x -= step.distance
    end
    self.direction = step.direction(direction)
  end

  def follow(steps_str)
    steps_str.strip
      .split(', ')
      .map { |step_str| Step.new(step_str) }
      .each { |step| step(step) }

    [x, y]
  end
end

@walker = Walker.new(0, 0, 'N')
# @steps = %Q(R2, L3)
# @steps = %Q(R2, R2, R2)
# @steps = %Q(R5, L5, R5, R3)
@steps = %Q(L1, R3, R1, L5, L2, L5, R4, L2, R2, R2, L2, R1, L5, R3, L4, L1, L2, R3, R5, L2, R5, L1, R2, L5, R4, R2, R2, L1, L1, R1, L3, L1, R1, L3, R5, R3, R3, L4, R4, L2, L4, R1, R1, L193, R2, L1, R54, R1, L1, R71, L4, R3, R191, R3, R2, L4, R3, R2, L2, L4, L5, R4, R1, L2, L2, L3, L2, L1, R4, R1, R5, R3, L5, R3, R4, L2, R3, L1, L3, L3, L5, L1, L3, L3, L1, R3, L3, L2, R1, L3, L1, R5, R4, R3, R2, R3, L1, L2, R4, L3, R1, L1, L1, R5, R2, R4, R5, L1, L1, R1, L2, L4, R3, L1, L3, R5, R4, R3, R3, L2, R2, L1, R4, R2, L3, L4, L2, R2, R2, L4, R3, R5, L2, R2, R4, R5, L2, L3, L2, R5, L4, L2, R3, L5, R2, L1, R1, R3, R3, L5, L2, L2, R5)