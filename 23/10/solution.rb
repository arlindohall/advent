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

    flood_outer

    expand_border until @border.empty?

    _debug(
      "enclosed",
      total_size:,
      ymax: @ymax,
      xmax: @xmax,
      visited: @visited.size,
      exposed: @exposed.size
    )
    total_size - @visited.size - @exposed.size
  end

  def total_size
    @ymax * @xmax
  end

  def expand_border
    border_coords = @border.map { |border| border.coordinates }
    _debug("expanding", border: border_coords, exposed: @exposed)
    @exposed += border_coords
    @border =
      @border
        .flat_map { |border_space| border_space.all_neighbors }
        .reject { |neighbor| @exposed.include?(neighbor) }
        .to_set
        .map { |neighbor| maybe_fitting(neighbor) }
        .compact
        .reject { |neighbor| @visited[neighbor] }
  end

  def flood_outer
    @border, @exposed = [], Set.new

    @xmax, @ymax = max_values

    (0).upto(@xmax - 1) do |x|
      @border << maybe_fitting([x, 0])
      @border << maybe_fitting([x, @ymax - 1])
    end
    (1).upto(@ymax - 2) do |y|
      @border << maybe_fitting([0, y])
      @border << maybe_fitting([@xmax - 1, y])
    end

    @border.reject! { |fitting| fitting.nil? || @visited[fitting] }
  end

  def max_values
    rows = @text.split("\n").size
    cols = @text.split("\n").first.chars.count

    [cols, rows]
  end

  def maybe_fitting((x, y))
    # raise "Fitting out of bounds" if x < 0 || y < 0 || x >= @xmax || y >= @ymax
    # raise "Fitting wasn't mapped: #{[x, y]}" unless fitting([x,y])
    return nil if x < 0 || y < 0 || x >= @xmax || y >= @ymax

    fitting([x, y])
  end

  def setup
    @steps = 0
    @states = [start]
    @visited = Hash.new
  end

  def increment
    _debug("incrementing states", steps: @steps, states: @states)

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
end

class Fitting
  attr_reader :coordinates
  def initialize(coordinates)
    @coordinates = coordinates
  end

  def x = coordinates[0]
  def y = coordinates[1]

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

  def start? = false
end

class Vertical < Fitting
  def reachable
    [[x, y + 1], [x, y - 1]]
  end
end

class Horizontal < Fitting
  def reachable
    [[x + 1, y], [x - 1, y]]
  end
end

class BottomRight < Fitting
  def reachable
    [[x + 1, y], [x, y + 1]]
  end
end

class BottomLeft < Fitting
  def reachable
    [[x - 1, y], [x, y + 1]]
  end
end

class TopLeft < Fitting
  def reachable
    [[x - 1, y], [x, y - 1]]
  end
end

class TopRight < Fitting
  def reachable
    [[x + 1, y], [x, y - 1]]
  end
end

class StartingPoint < Fitting
  def reachable = neighbors
  def start? = true
end

class NullFitting < Fitting
  def reachable = []
end
