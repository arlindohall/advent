
Coordinate = Struct.new(:row, :col)
class Coordinate
  def value_at
    col.upto(row-2+col).sum + starting_col
  end

  def starting_col
    @col ||= 1.upto(col).sum
  end
end

Hasher = Struct.new(:repeat)
class Hasher
  INITIAL_HASH = 20151125
  CACHE = {1 => INITIAL_HASH}

  def hash
    value = INITIAL_HASH
    (repeat-1).times do
      value = value * 252533 % 33554393
    end

    CACHE[repeat] = value
  end

  def previous
    Hasher.new(repeat - 1).hash
  end
end

Grid = Struct.new(:length, :height, :compute)
class Grid
  def show
    @show ||= values.map do |row|
      row.map do |value|
        value.to_s.ljust(max_length + 1)
      end.join
    end.join("\n")
  end

  def max_length
    @max_length ||= values.map do |row|
      row.map(&:to_s).map(&:length).max
    end.max
  end

  def values
    @values ||= 1.upto(length).map do |row|
      1.upto(height).map do |col|
        compute.call(row, col)
      end
    end
  end
end

def part1
  Hasher.new(Coordinate.new(2981, 3075).value_at).hash
end

# 28836990 <- too high, forgot to subtract 1 from repeat