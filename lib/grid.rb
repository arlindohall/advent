
module Coordinates
  def adjacent(x, y)
    [
      [x+1, y],
      [x-1, y],
      [x, y+1],
      [x, y-1],
      [x+1, y-1],
      [x+1, y+1],
      [x-1, y-1],
      [x-1, y+1],
    ].filter { |x,y| in_bounds?(x, y) }
  end

  def neighbors(x, y)
    [
      [x+1, y],
      [x-1, y],
      [x, y+1],
      [x, y-1],
    ].filter { |x,y| in_bounds?(x, y) }
  end

  def corners(x, y)
    [
      [x+1, y-1],
      [x+1, y+1],
      [x-1, y-1],
      [x-1, y+1],
    ].filter { |x,y| in_bounds?(x, y) }
  end

  def in_bounds(x, y)
    raise "Not implemented for class #{self.class}"
  end
end

class SparseGrid
  include Coordinates

  def in_bounds?(x, y)
    true
  end
end

class Grid
  include Coordinates

  def initialize(grid)
    @grid = grid
  end

  def self.parse(text)
    new(text.strip.split("\n").map(&:chars))
  end

  def to_s
    @grid.map(&:join).join("\n")
  end

  def in_bounds?(x, y)
    x >= 0 &&
      x < @grid.first.size &&
      y >= 0 &&
      y < @grid.size
  end
end