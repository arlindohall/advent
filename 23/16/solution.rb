def solve(input = read_input) =
  FloorLava.new(input).then { |fl| [fl.energized.count, fl.max_energized] }

class FloorLava
  def initialize(text)
    @text = text
  end

  def layout
    @text
      .split("\n")
      .each_with_index
      .flat_map do |line, y|
        line.chars.each_with_index.map { |ch, x| Space.for(ch, x, y) }
      end
      .hash_by(&:coordinates)
  end

  def energized
    LaserPath.new(layout).shine
  end

  def max_energized
    starting_points.map { |start| LaserPath.new(layout, start).shine.count }.max
  end

  def starting_points
    xmin, xmax, ymin, ymax = LaserPath.new(layout).minmax

    [
      xmin.upto(xmax).map { |x| Location[[x, ymin], [0, 1]] },
      xmin.upto(xmax).map { |x| Location[[x, ymax], [0, -1]] },
      ymin.upto(ymax).map { |y| Location[[xmin, y], [1, 0]] },
      ymin.upto(ymax).map { |y| Location[[xmax, y], [-1, 0]] }
    ].flatten
  end
end

class LaserPath
  def initialize(mirrors, start = Location.beginning)
    @mirrors = mirrors
    @start = start
  end

  def shine
    @locations = [@start]

    # Could skip visited and track every square traceable to each
    # other square, and memoize that at the class level
    while @locations.any?
      @locations.each { |loc| visit(loc) }
      @locations =
        @locations
          .flat_map { |loc| propagate(loc) }
          .reject { |loc| visited?(loc) }
          .reject { |loc| loc.invalid?(minmax) }
    end

    visited
  end

  def visited?(location)
    visited.has_key?(location.coords) &&
      visited[location.coords].include?(location.velocity)
  end

  def visit(location)
    visited[location.coords] ||= []
    visited[location.coords] << location.velocity
  end

  def visited
    @visited ||= {}
  end

  def propagate(location)
    @mirrors[location.coords].propagate(location.velocity)
  end

  memoize def minmax
    [
      @mirrors.keys.map(&:first).minmax,
      @mirrors.keys.map(&:last).minmax
    ].flatten
  end
end

class Location < Struct.new(:coords, :velocity)
  def self.beginning
    new([0, 0], [1, 0])
  end

  def invalid?((xmin, xmax, ymin, ymax))
    dx, dy = velocity
    raise "Invalid velocity: #{velocity}" unless dx.abs + dy.abs == 1

    x, y = coords
    return true if x < xmin || x > xmax
    return true if y < ymin || y > ymax

    false
  end
end

class Space
  def self.for(character, x, y)
    case character
    when "."
      Empty
    when "|"
      VerticalSplit
    when "-"
      HorizontalSplit
    when "/"
      RightMirror
    when "\\"
      LeftMirror
    end.new(x, y)
  end

  def initialize(x, y)
    @x, @y = x, y
  end

  def coordinates
    [@x, @y]
  end
end

class Empty < Space
  def propagate(signal)
    dx, dy = signal
    [Location[[@x + dx, @y + dy], signal]]
  end
end

class VerticalSplit < Space
  def propagate(signal)
    dx, dy = signal
    return [Location[[@x + dx, @y + dy], signal]] if dx == 0

    [Location[[@x, @y + 1], [0, 1]], Location[[@x, @y - 1], [0, -1]]]
  end
end

class HorizontalSplit < Space
  def propagate(signal)
    dx, dy = signal
    return [Location[[@x + dx, @y + dy], signal]] if dy == 0

    [Location[[@x + 1, @y], [1, 0]], Location[[@x - 1, @y], [-1, 0]]]
  end
end

class LeftMirror < Space
  def propagate(signal)
    dx, dy = signal
    return [Location[[@x + 1, @y], [1, 0]]] if dy == 1
    return [Location[[@x - 1, @y], [-1, 0]]] if dy == -1
    return [Location[[@x, @y + 1], [0, 1]]] if dx == 1
    return [Location[[@x, @y - 1], [0, -1]]] if dx == -1
  end
end

class RightMirror < Space
  def propagate(signal)
    dx, dy = signal
    return [Location[[@x + 1, @y], [1, 0]]] if dy == -1
    return [Location[[@x - 1, @y], [-1, 0]]] if dy == 1
    return [Location[[@x, @y + 1], [0, 1]]] if dx == -1
    return [Location[[@x, @y - 1], [0, -1]]] if dx == 1
  end
end
