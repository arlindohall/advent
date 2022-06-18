
class Maze
  def initialize(magic_number)
    Point.set_magic_number(magic_number)
  end

  def shortest_path(destination)
    reset_distance
    visit([1,1])
    until visited?(destination)
      increment_distance
      reachable.each do |point|
        visit(point)
      end
    end

    @distance
  end

  def walk(distance)
    reset_distance
    visit([1,1])
    while @distance < distance
      increment_distance
      reachable.each do |point|
        visit(point)
      end
    end

    @distances.size
  end

  def reachable
    last_points.flat_map do |point|
      neighbors(point).filter do |neighbor|
        x, y = neighbor
        !visited?(neighbor) && !is_wall(x, y)
      end
    end
  end

  def neighbors(point)
    x, y = point
    [
      [x-1, y],
      [x+1, y],
      [x, y-1],
      [x, y+1]
    ].filter do |neighbor|
      neighbor.first >= 0 && neighbor.last >= 0
    end
  end

  def last_points
    @visited[@distance-1]
  end

  def visited?(point)
    @distances ||= {}
    @visited ||= {}
    @distances.include?(point)
  end

  def visit(point)
    return if visited?(point)
    @visited[@distance] ||= []

    @distances[point] = @distance
    @visited[@distance] << point
  end

  def increment_distance
    @distance += 1
  end

  def reset_distance
    @distance = 0
  end

  def distance
    @distance
  end

  def is_wall?(i, j)
    Point.new(i, j).is_wall?
  end

  def show
    puts "  0123456789"
    0.upto(6) do |j|
      puts "#{j} " + row_to_s(j)
    end
  end

  def row_to_s(j)
    0.upto(9).map do |i|
      is_wall?(i, j) ? '#' : '.'
    end.join
  end
end

class Point
  def self.set_magic_number(magic_number)
    @@magic_number = magic_number
  end

  def initialize(i, j)
    @x, @y = i, j
  end

  def is_wall?
    number_of_ones.odd?
  end

  def number_of_ones
    binary_representation.chars.map(&:to_i).sum
  end

  def binary_representation
    sum.to_s(2)
  end

  def sum
    calculation + @@magic_number
  end

  def calculation
    @x*@x + 3*@x + 2*@x*@y + @y + @y*@y
  end
end

def part1
  Maze.new(1350).shortest_path([31, 39])
end

def part2
  Maze.new(1350).walk(50)
end