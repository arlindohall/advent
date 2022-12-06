
class Eris
  def initialize(grid = Set.new)
    @grid = grid
  end

  def solve
    dup.first_double.biodiversity_rating
  end

  def biodiversity_rating
    score = 0
    in_order do |i, x, y|
      score |= 1 << i if bug?(x, y)
    end
    score
  end

  def in_order
    i = 0
    0.upto(4) do |y|
      0.upto(4) do |x|
        yield [i, x, y]
        i += 1
      end
    end
  end

  def first_double
    loop do
      return self if seen?
      update
    end
  end

  def update
    @seen << @grid
    @grid = updated_grid
  end

  def seen?
    @seen ||= Set.new
    @seen.include?(@grid)
  end

  def updated_grid
    (points + neighbors).map do |x, y|
      [x,y] if should_be_bug?(x, y)
    end.compact
       .filter { |x, y| in_bounds?(x, y) }
       .to_set
  end

  def points
    @grid
  end

  def neighbors
    points.flat_map { |x, y| neighbors_of(x, y) }
  end

  def neighbors_of(x, y)
    [
      [x + 1, y],
      [x - 1, y],
      [x, y + 1],
      [x, y - 1],
    ]
  end

  def should_be_bug?(x, y)
    bug_and_cozy?(x, y) || empty_and_available?(x, y)
  end

  def bug_and_cozy?(x, y)
    bug?(x, y) &&
      neighbors_of(x, y).filter { |x, y| bug?(x, y) }.count == 1
  end

  def empty_and_available?(x, y)
    !bug?(x, y) &&
      [1,2].include?(neighbors_of(x, y).filter { |x, y| bug?(x, y) }.count)
  end

  def in_bounds?(x, y)
    x >= 0 && x < 5 && y >= 0 && y < 5
  end

  def bug?(x, y)
    @grid.include?([x,y])
  end

  def debug
    0.upto(4) do |y|
      0.upto(4) do |x|
        print '#' if bug?(x, y)
        print '.' unless bug?(x, y)
      end
      puts
    end
  end

  class << self
    def parse(text)
      grid = Set.new
      text.split("\n").each_with_index do |row, y|
        row.chars.each_with_index do |ch, x|
          grid << [x, y] if ch == '#'
        end
      end

      new(grid)
    end
  end
end

class ErisRecursive
  def initialize(grid = Set.new)
    @grid = grid
  end

  def solve
    200.times { update }
    @grid.size
  end

  def update
    @grid = updated_grid
  end

  def updated_grid
    (points + neighbors).map do |level, x, y|
      [level, x, y] if should_be_bug?(level, x, y)
    end.compact
       .filter { |_level, x, y| in_bounds?(x, y) }
       .to_set
  end

  def points
    @grid
  end

  def neighbors
    points.flat_map { |level, x, y| neighbors_of(level, x, y) }
  end

  def neighbors_of(level, x, y)
    level_neighbrs_of(level, x, y) + recursive_neighbors_of(level, x, y)
  end

  def level_neighbrs_of(level, x, y)
    [
      [level, x + 1, y],
      [level, x - 1, y],
      [level, x, y + 1],
      [level, x, y - 1],
    ]
  end

  def recursive_neighbors_of(level, x, y)
    neighbors = []

    neighbors << [level + 1, 1, 2] if x == 0
    neighbors << [level + 1, 3, 2] if x == 4
    neighbors << [level + 1, 2, 1] if y == 0
    neighbors << [level + 1, 2, 3] if y == 4

    case [x, y]
    when [2, 1] ; neighbors += level_down(level, :y, 0)
    when [2, 3] ; neighbors += level_down(level, :y, 4)
    when [1, 2] ; neighbors += level_down(level, :x, 0)
    when [3, 2] ; neighbors += level_down(level, :x, 4)
    end

    neighbors
  end

  def level_down(level, axis, constant)
    if axis == :x
      return 0.upto(4).map { [level - 1, constant, _1] }
    end

    if axis == :y
      return 0.upto(4).map { [level - 1, _1, constant] }
    end

    raise "WTF axis=#{axis}"
  end

  def should_be_bug?(level, x, y)
    bug_and_cozy?(level, x, y) || empty_and_available?(level, x, y)
  end

  def bug_and_cozy?(level, x, y)
    bug?(level, x, y) &&
      neighbors_of(level, x, y).filter { |level, x, y| bug?(level, x, y) }.count == 1
  end

  def empty_and_available?(level, x, y)
    !bug?(level, x, y) &&
      [1,2].include?(neighbors_of(level, x, y).filter { |level, x, y| bug?(level, x, y) }.count)
  end

  def in_bounds?(x, y)
    return false if x == 2 && y == 2

    x >= 0 && x < 5 && y >= 0 && y < 5
  end

  def bug?(level, x, y)
    @grid.include?([level, x, y])
  end

  def debug
    0.upto(4) do |y|
      0.upto(4) do |x|
        print '#' if bug?(x, y)
        print '.' unless bug?(x, y)
      end
      puts
    end
  end

  class << self
    def parse(text)
      grid = Set.new
      text.split("\n").each_with_index do |row, y|
        row.chars.each_with_index do |ch, x|
          grid << [0, x, y] if ch == '#'
        end
      end

      new(grid)
    end
  end
end

def solve
  [Eris.sove, ErisRecursive.solve]
end

@example = <<-bugs.strip
....#
#..#.
#..##
..#..
#....
bugs

@input =  <<-bugs.strip
#..#.
.....
.#..#
.....
#.#..
bugs