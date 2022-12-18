
$debug = false

class Navigator < Struct.new(:text)
  def instructions
    @instructions ||= text.split.map { Instruction[_1] }
  end

  attr_accessor :location, :direction
  def follow
    self.location ||= [0, 0]
    self.direction ||= "E"
    instructions.each do |ins|
      self.location, self.direction = move(ins)
      debug
    end

    location.map(&:abs).sum
  end

  def waypoint
    WaypointNavigator.new(text)
  end

  def move(instruction)
    [new_location(instruction), new_direction(instruction)]
  end

  def new_location(instruction)
    return location if instruction.action == "R"
    return location if instruction.action == "L"
    return forward(instruction.distance) if instruction.action == "F"

    x, y = location
    dx, dy = change_in_location(instruction.action, instruction.distance)

    [x + dx, y + dy]
  end

  def forward(distance)
    x, y = location
    dx, dy = change_in_location(direction, distance)

    [x + dx, y + dy]
  end

  def change_in_location(direction, distance)
    case direction
    when "N" then [0, distance]
    when "S" then [0, -distance]
    when "E" then [distance, 0]
    when "W" then [-distance, 0]
    else
      raise "Unexpected direction #{direction}"
    end
  end

  def new_direction(instruction)
    dir = direction
    case instruction.action
    when "R" then instruction.turns.times { dir = turn_right(dir) }
    when "L" then instruction.turns.times { dir = turn_left(dir) }
    end

    dir
  end

  def turn_right(current_dir)
    case current_dir
    when "N" then "E"
    when "E" then "S"
    when "S" then "W"
    when "W" then "N"
    end
  end

  def turn_left(current_dir)
    case current_dir
    when "N" then "W"
    when "W" then "S"
    when "S" then "E"
    when "E" then "N"
    end
  end

  def debug
    return unless $debug
    print location.first.positive? ? "east" : "west"
    print " #{location.first.abs}, "
    print location.last.positive? ? "north" : "south"
    print " #{location.last.abs}, "
    puts "facing #{direction}"
  end
end

class WaypointNavigator < Navigator
  attr_accessor :waypoint_location
  def follow
    self.location ||= [0, 0]
    self.waypoint_location ||= [10, 1]
    instructions.each do |ins|
      self.waypoint_location = move_waypoint(ins)
      self.location = move(ins)
      debug
    end

    location.map(&:abs).sum
  end

  def move(instruction)
    return location unless instruction.action == "F"

    x, y = location
    instruction.distance.times { x, y = follow_waypoint(x, y) }
    [x, y]
  end

  def follow_waypoint(x, y)
    dx, dy = waypoint_location

    [x + dx, y + dy]
  end

  def move_waypoint(instruction)
    return waypoint_location if instruction.action == "F"
    return rotate_left(instruction.turns) if instruction.action == "L"
    return rotate_right(instruction.turns) if instruction.action == "R"

    x, y = waypoint_location
    dx, dy = change_in_location(instruction.action, instruction.distance)

    [x + dx, y + dy]
  end

  # x -> -y; y -> x 
  # [1, 2]    -> [-2, 1]
  # [-2, 1]   -> [-1, -2]
  # [-1, -2]  -> [2, -1]
  # [2, -1]   -> [1, 2]
  def rotate_left(times)
    x, y = waypoint_location
    times.times { x, y = -y, x }
    [x, y]
  end


  # x -> y; y -> -x
  # [1, 2]   -> [2, -1]
  # [2, -1]  -> [-1, -2]
  # [-1, -2] -> [-2, 1]
  # [-2, 1]  -> [1, 2]
  def rotate_right(times)
    x, y = waypoint_location
    times.times { x, y = y, -x }
    [x, y]
  end

  def debug
    return unless $debug
    print location.first.positive? ? "east" : "west"
    print " #{location.first.abs}, "
    print location.last.positive? ? "north" : "south"
    print " #{location.last.abs} "
    print "// waypoint is "
    print waypoint_location.first.positive? ? "east" : "west"
    print " #{waypoint_location.first.abs}, "
    print waypoint_location.last.positive? ? "north" : "south"
    puts " #{waypoint_location.last.abs}"
  end
end

class Instruction < Struct.new(:line)
  def action
    line[0]
  end

  def distance
    line[1..].to_i
  end

  def turns
    (distance % 360) / 90
  end
end

def solve
  [
    Navigator.new(read_input).follow,
    Navigator.new(read_input).waypoint.follow,
  ]
end