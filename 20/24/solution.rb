$debug = false

def solve
  [
    TileFloor.new(read_input).black_tiles.count,
    TileFloor.new(read_input).one_hundred_days
  ]
end

class TileFloor < Struct.new(:text)
  def one_hundred_days
    100.times { day }

    black_tiles.count
  end

  def day
    @i ||= 0
    { i: @i += 1, black_tiles_count: black_tiles.count }.plop
    @black_tiles = all_neighbors.filter { |n| should_be_black?(n) }.to_set
  end

  def all_neighbors
    black_tiles.flat_map(&:neighbors).to_set + black_tiles
  end

  def should_be_black?(tile)
    return true if is_black?(tile) && one_or_two?(tile)
    return true if is_white?(tile) && two?(tile)

    false
  end

  def is_black?(tile)
    black_tiles.include?(tile)
  end

  def is_white?(tile)
    black_tiles.exclude?(tile)
  end

  def one_or_two?(tile)
    black_neighbors(tile).count.between?(1, 2)
  end

  def two?(tile)
    black_neighbors(tile).count == 2
  end

  def black_neighbors(tile)
    tile.neighbors.filter { |n| black_tiles.include?(n) }
  end

  def black_tiles
    @black_tiles ||= tiles.count_values.filter { |tile, count| count.odd? }.keys
  end

  def tiles
    instructions.map { |instruction| follow(instruction) }
  end

  def follow(instruction)
    tile = Coordinate.new(0, 0, 0)
    instruction.each { |inst| tile = tile.travel(inst) }

    tile
  end

  def instructions
    text.split.map { |line| line.scan(/ne|nw|se|sw|e|w/) }
  end

  class Coordinate < Struct.new(:q, :r, :s)
    def travel(direction)
      case direction
      when "ne"
        Coordinate[q + 1, r - 1, s]
      when "nw"
        Coordinate[q, r - 1, s + 1]
      when "se"
        Coordinate[q, r + 1, s - 1]
      when "sw"
        Coordinate[q - 1, r + 1, s]
      when "e"
        Coordinate[q + 1, r, s - 1]
      when "w"
        Coordinate[q - 1, r, s + 1]
      end
    end

    def distance(other)
      diff = self - other
      [diff.q, diff.r, diff.s].map(&:abs).sum
    end

    def -(other)
      Coordinate[q: q - other.q, r: r - other.r, s: s - other.s]
    end

    def neighbors
      [
        Coordinate[q + 1, r - 1, s],
        Coordinate[q + 1, r, s - 1],
        Coordinate[q, r - 1, s + 1],
        Coordinate[q, r + 1, s - 1],
        Coordinate[q - 1, r, s + 1],
        Coordinate[q - 1, r + 1, s]
      ]
    end
  end
end
