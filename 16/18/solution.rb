
class TrapFloor

  def initialize(first_row)
    @row = Row.parse(first_row)
  end

  def show
    rows do |row|
      puts row.tiles.map(&:value).join
    end
  end

  def count_safe
    @count ||= begin
      safe_count = 0
      rows do |row|
        safe_count += row.tiles.map(&:safe?).filter(&:itself).count
      end

      safe_count
    end
  end

  def build(size)
    @size = size
    self
  end

  def rows
    row, row_count = @row, 0
    until row_count == @size
      yield(row)
      row = row.next_row
      row_count += 1
    end
  end

  class Row
    attr_reader :tiles

    def initialize(tiles)
      @tiles = tiles
    end

    def self.parse(line)
      Row.new(line.strip.chars.map{|ch|Tile.new(ch)})
    end

    def next_row
      Row.new(@tiles.each_index.map do |index|
        tile(index)
      end)
    end

    def tile(index)
      if left(index).trap? && center(index).trap? && right(index).safe?
        TRAP
      elsif center(index).trap? && right(index).trap? && left(index).safe?
        TRAP
      elsif left(index).trap? && center(index).safe? && right(index).safe?
        TRAP
      elsif right(index).trap? && left(index).safe? && left(index).safe?
        TRAP
      else
        SAFE
      end
    end

    def left(index)
      if index <= 0
        SAFE
      else
        @tiles[index-1]
      end
    end

    def right(index)
      if index >= @tiles.length-1
        SAFE
      else
        @tiles[index+1]
      end
    end

    def center(index)
      @tiles[index]
    end
  end

  class Tile
    attr_reader :value
    def initialize(value)
      @value = value
    end

    def trap?
      value == TRAP.value
    end

    def safe?
      value == SAFE.value
    end
  end

  SAFE = Tile.new(".")
  TRAP = Tile.new("^")
end

@prelim_example = TrapFloor.new("..^^.").build(3)
@example = TrapFloor.new(".^^.^.^^^^").build(10)
@input = TrapFloor.new("...^^^^^..^...^...^^^^^^...^.^^^.^.^.^^.^^^.....^.^^^...^^^^^^.....^.^^...^^^^^...^.^^^.^^......^^^^").build(40)
@part2 = TrapFloor.new("...^^^^^..^...^...^^^^^^...^.^^^.^.^.^^.^^^.....^.^^^...^^^^^^.....^.^^...^^^^^...^.^^^.^^......^^^^").build(400000)