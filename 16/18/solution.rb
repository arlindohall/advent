
class TrapFloor

  def initialize(first_row)
    @rows = [Row.parse(first_row)]
  end

  def show
    @rows.each do |row|
      puts row.tiles.map(&:value).join
    end
  end

  def count_safe
    @rows.map do |row|
      row.tiles.filter{|t|t.safe?}.count
    end.sum
  end

  def build(size)
    until @rows.size == size
      @rows << @rows.last.next_row
    end
    self
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