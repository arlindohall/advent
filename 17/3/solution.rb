
Coordinate = Struct.new(:x, :y)

class Coordinate
  def next(direction)
    case direction
    when :right
      Coordinate.new(x + 1, y)
    when :up
      Coordinate.new(x, y + 1)
    when :left
      Coordinate.new(x - 1, y)
    when :down
      Coordinate.new(x, y - 1)
    else
      raise "Unknown direction #{direction}"
    end
  end

  def neighbors
    cluster - [self]
  end

  def cluster
    (x-1).upto(x+1).map do |x|
      (y-1).upto(y+1).map do |y|
        Coordinate.new(x, y)
      end
    end.flatten
  end
end

class Grid
  def initialize
    @points = {}
    # First "direction" is right, but we "turn" after placing the
    # initial point to the right, before placing the second
    @direction = :down
  end

  def fill_until(value)
    if @points.empty?
      # Set first value if missing because we check the last value
      fill(0, 0, 1)
    end

    while last_value < value
      fill_next
    end

    [@last_coordinate, last_value]
  end

  def fill_next
    coordinate = next_coordinate
    fill(coordinate.x, coordinate.y, next_value)
  end

  def next_coordinate
    if should_rotate?
      rotate
    end

    @last_coordinate.next(@direction)
  end

  def neighbors
    next_coordinate.neighbors.filter{|c| @points.include?(c)}
  end

  def should_rotate?
    case @direction
    when :right
      nothing?(:up)
    when :up
      nothing?(:left)
    when :left
      nothing?(:down)
    when :down
      nothing?(:right)
    else
      raise "Unknown direction: #{@direction}"
    end
  end

  def nothing?(direction)
    !@points.include?(@last_coordinate.next(direction))
  end

  def fill(x, y, value)
    @last_coordinate = Coordinate.new(x, y)
    @points[@last_coordinate] = value
  end

  def last_value
    @points[@last_coordinate]
  end

  def rotate
    case @direction
    when :right
      @direction = :up
    when :up
      @direction = :left
    when :left
      @direction = :down
    when :down
      @direction = :right
    else
      raise "Unknown direction: #{@direction}"
    end
  end
end

class IncrementalGrid < Grid
  def next_value
    last_value + 1
  end
end

class SumGrid < Grid
  def next_value
    neighbors.map{|n| @points[n]}.sum
  end
end

def part1
  IncrementalGrid.new
    .fill_until(265149)
    .first
    .values
    .map(&:abs)
    .sum
end