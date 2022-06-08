
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
      [x, y + step.distance, 'N']
    when 'S'
      [x, y - step.distance, 'S']
    when 'E'
      [x + step.distance, y, 'E']
    when 'W'
      [x - step.distance, y, 'W']
    end
  end

  def visited
    @visited ||= Set.new
  end

  def visited?(step)
    return covered(step).filter{|p| visited.include?(p)}.first
  end

  def covered(step)
    new_x, new_y, new_dir = self.step(step)
    case new_dir
    when 'N'
      y.upto(new_y-1).map { |y| [x, y] }
    when 'S'
      (new_y+1).upto(y).map { |y| [x, y] }
    when 'E'
      x.upto(new_x-1).map { |x| [x, y] }
    when 'W'
      (new_x+1).upto(x).map { |x| [x, y] }
    end
  end

  def follow(steps_str)
    steps_str.strip
      .split(', ')
      .map { |step_str| Step.new(step_str) }
      .each { |step|
        return visited?(step) if visited?(step)
        covered(step).each { |p| visited.add(p) }
        self.x, self.y, self.direction = step(step)
      }
  end
end

@walker = Walker.new(0, 0, 'N')
@steps = %Q(L1, R3, R1, L5, L2, L5, R4, L2, R2, R2, L2, R1, L5, R3, L4, L1, L2, R3, R5, L2, R5, L1, R2, L5, R4, R2, R2, L1, L1, R1, L3, L1, R1, L3, R5, R3, R3, L4, R4, L2, L4, R1, R1, L193, R2, L1, R54, R1, L1, R71, L4, R3, R191, R3, R2, L4, R3, R2, L2, L4, L5, R4, R1, L2, L2, L3, L2, L1, R4, R1, R5, R3, L5, R3, R4, L2, R3, L1, L3, L3, L5, L1, L3, L3, L1, R3, L3, L2, R1, L3, L1, R5, R4, R3, R2, R3, L1, L2, R4, L3, R1, L1, L1, R5, R2, R4, R5, L1, L1, R1, L2, L4, R3, L1, L3, R5, R4, R3, R3, L2, R2, L1, R4, R2, L3, L4, L2, R2, R2, L4, R3, R5, L2, R2, R4, R5, L2, L3, L2, R5, L4, L2, R3, L5, R2, L1, R1, R3, R3, L5, L2, L2, R5)
# @steps = %Q(R8, R4, R4, R8)