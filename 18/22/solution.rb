
class Cave
  def initialize(depth, target, bounds = nil)
    @depth = depth
    @target = target
    @bounds = bounds || target
  end

  def geologic_index
    return @geologic_index if @geologic_index

    x,y = @bounds
    @geologic_index = 0.upto(y).map { 0.upto(x).map { 0 } }

    0.upto(x) { |x| @geologic_index[0][x] = mod(x * 16807) }
    0.upto(y) { |y| @geologic_index[y][0] = mod(y * 48271) }

    1.upto(y) { |y|
      1.upto(x) { |x|
        @geologic_index[y][x] = mod(erosion_level(x, y-1) * erosion_level(x-1, y))
      }
    }

    @geologic_index
  end

  def erosion_level(x, y)
    @erosion_level ||= 0.upto(@bounds.last).map { 0.upto(@bounds.first).map { -1 } }

    return @erosion_level[y][x] unless @erosion_level[y][x] == -1

    @erosion_level[y][x] = mod(geologic_index[y][x] + @depth)
  end

  def type(x, y)
    erosion_level(x, y) % 3
  end

  def risk_level
    x, y = @target
    0.upto(y).flat_map { |y|
      0.upto(x).map { |x|
        type(x, y) unless [x,y] == @target
      }.compact
    }.sum
  end

  def mod(value)
    value % 20183
  end

  def to_s
    geologic_index.each_index.map { |y|
      geologic_index[y].each_index.map { |x|
        [x,y] == [0,0] ? 'M' : (
          [x,y] == @target ? 'T' : (
            case type(x, y)
            when 0 then '.' # rocky
            when 1 then '=' # wet
            when 2 then '|' # narrow
            end
          )
        )
      }.join
    }.join("\n")
  end

  def dump
    puts to_s
  end
end

def solve
  c = Cave.new(4080, [14, 785])
  [c.risk_level, c.fastest_path]
end