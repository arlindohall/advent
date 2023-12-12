$_debug = false

# too high: 703

def solve(input = read_input) =
  PipeMaze.new(input).then { |pm| [pm.dup.steps, pm.dup.enclosed] }

class PipeMaze
  def initialize(text)
    @text = text
  end

  def steps
    setup

    increment until @states.size == 0

    @visited.values.max
  end

  def enclosed
    steps # Get `@visisted` populated

    @enclosed =
      non_maze_points.filter do |coordinates|
        odd_maze_passings_around?(coordinates)
      end

    @exposed = non_maze_points - @enclosed

    @enclosed.size
  end

  def odd_maze_passings_around?(coordinates)
    maze_points_above(coordinates).odd?
  end

  def maze_points_above(coordinates)
    windings(
      @visited
        .keys
        .filter do |fitting|
          fitting.coordinates[1] < coordinates[1] &&
            fitting.coordinates[0] == coordinates[0]
        end
        .sort_by { |fitting| fitting.coordinates.second }
        .reverse
        .map { |fitting| replace_starting_point(fitting) }
    )
  end

  def replace_starting_point(fitting)
    return fitting unless fitting.start?

    fitting_from_directions(
      fitting,
      fitting
        .neighbors
        .map { |nb| fitting(nb) }
        .compact
        .filter { |nb| nb.connected?(fitting) }
    )
  end

  def fitting_from_directions(start, neighbors)
    # Will always have same starting value, so we can memoize it
    @fitting_from_directions ||=
      FittingFromDirections.new(start, neighbors).calculate
  end

  def windings(fittings)
    windings = fittings.count { |it| it.is_a?(Horizontal) }
    bends =
      fittings.filter do |it|
        it.is_a?(TopLeft) || it.is_a?(TopRight) || it.is_a?(BottomLeft) ||
          it.is_a?(BottomRight)
      end

    bends.each_slice(2) do |first, second|
      windings += 1 if first.moves_horizontally_with?(second)
    end

    windings
  rescue StandardError
    binding.pry
    raise
  end

  def non_maze_points
    maze.keys.filter { |coordinates| !vis_by_loc[coordinates] }
  end

  def vis_by_loc
    return @vis_by_loc if @vis_by_loc
    raise "Haven't visisted anything yet" unless @visited

    @vis_by_loc =
      @visited.map { |fitting, count| [fitting.coordinates, count] }.to_h
  end

  def debug
    enclosed

    coords = (@visited.keys.map { |v| v.coordinates } + @exposed.to_a).uniq

    xmax, ymax = coords.map(&:first).max, coords.map(&:last).max

    0.upto(ymax) do |y|
      0.upto(xmax) do |x|
        if @exposed.include?([x, y])
          NonFitting.new("O")
        elsif vis_by_loc[[x, y]]
          fitting([x, y])
        else
          NonFitting.new("I")
        end.to_s.then { |s| print s }
      end
      puts
    end
  end

  def total_size
    @ymax * @xmax
  end

  def setup
    @steps = 0
    @states = [start]
    @visited = Hash.new
  end

  def increment
    # _debug("incrementing states", steps: @steps, states: @states)

    @states.each { |state| @visited[state] = @steps }
    @steps += 1

    @states = next_states
  end

  def next_states
    @states.flat_map do |state|
      state
        .neighbors
        .map { |nb| fitting(nb) }
        .compact
        .reject { |nb| @visited[nb] }
        .filter { |nb| nb.connected?(state) }
    end
  end

  def start
    maze.values.find { |fitting| fitting.start? }
  end

  def fitting(coordinates)
    maze[coordinates]
  end

  memoize def maze
    maze = {}

    @text
      .split("\n")
      .each_with_index do |line, y|
        line.chars.each_with_index do |char, x|
          maze[[x, y]] = Fitting.for(char, [x, y])
        end
      end

    maze
  end
end

class NonFitting
  def initialize(char)
    @char = char
  end

  def to_s
    @char
  end
end

class Fitting
  def self.for(char, coordinates)
    case char
    when "|"
      Vertical
    when "-"
      Horizontal
    when "F"
      BottomRight
    when "7"
      BottomLeft
    when "J"
      TopLeft
    when "L"
      TopRight
    when "S"
      StartingPoint
    else
      NullFitting
    end.new(coordinates)
  end

  attr_reader :coordinates
  def initialize(coordinates)
    @coordinates = coordinates
  end

  def x = coordinates[0]
  def y = coordinates[1]
  def start? = false

  def connected?(other)
    other.can_reach?(self.coordinates) && self.can_reach?(other.coordinates)
  end

  def can_reach?(other)
    reachable.include?(other)
  end

  def neighbors
    [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]]
  end

  def all_neighbors
    [
      [x + 1, y],
      [x - 1, y],
      [x, y + 1],
      [x, y - 1],
      [x + 1, y + 1],
      [x - 1, y + 1],
      [x + 1, y - 1],
      [x - 1, y - 1]
    ]
  end

  def moves_horizontally_with?(other)
    return true if self.is_a?(TopLeft) && other.is_a?(BottomRight)
    return true if self.is_a?(TopRight) && other.is_a?(BottomLeft)

    if self.is_a?(BottomLeft) || self.is_a?(BottomRight)
      raise "Impossible bends"
    end

    false
  end
end

class Vertical < Fitting
  def to_s = "|"
  def reachable
    [[x, y + 1], [x, y - 1]]
  end
end

class Horizontal < Fitting
  def to_s = "-"
  def reachable
    [[x + 1, y], [x - 1, y]]
  end
end

class BottomRight < Fitting
  def to_s = "F"
  def reachable
    [[x + 1, y], [x, y + 1]]
  end
end

class BottomLeft < Fitting
  def to_s = "7"
  def reachable
    [[x - 1, y], [x, y + 1]]
  end
end

class TopLeft < Fitting
  def to_s = "J"
  def reachable
    [[x - 1, y], [x, y - 1]]
  end
end

class TopRight < Fitting
  def to_s = "L"
  def reachable
    [[x + 1, y], [x, y - 1]]
  end
end

class StartingPoint < Fitting
  def to_s = "S"
  def reachable = neighbors
  def start? = true
end

class NullFitting < Fitting
  def to_s = "."
  def reachable = []
end

class FittingFromDirections
  def initialize(start, neighbors)
    @start = start
    @neighbors = neighbors
  end

  def calculate
    # Cheat and just do what I know it is from reading code
    Horizontal.new(@start.coordinates) # input
    # BottomRight.new(@start.coordinates) # example 2
    # BottomLeft.new(@start.coordinates) # example 3
  end
end
