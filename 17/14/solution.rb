
class Disk
  def initialize(key)
    @key = key
  end

  def self.construct(key)
    new(key)
  end

  def grid
    @grid ||= 128.times.map do |row|
      knot_hash(row)
    end
  end

  def knot_hash(row)
    KnotHash.of("#{@key}-#{row}")
      .binary_hash
      .chars
      .map{|ch| ch == '1' ? '#' : '.'}
  end

  def solve
    [used, groups.count]
  end

  def show
    0.upto(7) do |row|
      puts grid[row][0..7].join
    end
  end

  def used
    grid.flatten.count('#')
  end

  def groups
    return @groups if @groups
    @groups = []

    grid.each_index do |row_index|
      grid[row_index].each_index do |cell_index|
        add_group(row_index, cell_index) if grid[row_index][cell_index] == '#'
      end
    end

    @groups
  end

  def add_group(x, y)
    return if @groups.any? { |group| group.include?([x, y]) }

    @group = [[x, y]]
    @queue = neighbors(x, y)
    while !@queue.empty?
      add_one_to_group(@queue.pop)
    end

    @groups << @group
  end

  def neighbors(x, y)
    possible_neighbors(x, y)
      .filter{|p| x, y = p ; grid[x][y] == '#'}
  end

  def possible_neighbors(x, y)
    neighbors = []
    neighbors << [x-1, y] if x > 0
    neighbors << [x+1, y] if x < @grid.size-1
    neighbors << [x, y-1] if y > 0
    neighbors << [x, y+1] if y < @grid.first.size-1
    neighbors
  end

  def add_one_to_group(point)
    @group << point
    neighbors(*point)
      .filter{|p| !@group.include?(p)}
      .each{|n| @queue << n}
  end
end

class KnotHash
  APPEND_INSTRUCTIONS = [17, 31, 73, 47, 23]

  def initialize(list, lengths)
    @list = list
    @instructions = lengths
    @skip_size = 0
    @rotations = 0
  end

  def self.of(key)
    new(256.times.to_a, key.bytes).dup
  end

  def solve
    [
      dup.one_round_only.take(2).reduce(&:*),
      dup.hex_hash
    ]
  end

  def dup
    KnotHash.new(@list.dup, @instructions.dup)
  end

  def hex_hash
    dense_hash.map{|h| h.to_s(16).rjust(2, '0')}.join
  end

  def dense_hash
    sparse_hash.each_slice(16)
      .map{|slice| slice.reduce(&:"^")}
  end

  def sparse_hash
    expand_instructions
    64.times{ twist }
    un_rotate

    @list
  end

  def expand_instructions
    @instructions = ascii_instructions + APPEND_INSTRUCTIONS
  end

  def ascii_instructions
    # Unlike input for day 10, I've already given ascii byte input
    @instructions
  end

  def one_round_only
    twist
    un_rotate

    @list
  end

  def twist
    @instructions.each { |length| twist_once(length) }
  end

  def twist_once(length)
    @length = length
    reverse_n
    rotate
    increment_skip_size
  end

  def reverse_n
    i, j = 0, @length - 1
    while i < j
      @list[i], @list[j] = @list[j], @list[i]
      i, j = i+1, j-1
    end
  end

  def rotate
    @rotations += @length + @skip_size
    @list.rotate!(@length + @skip_size)
  end

  def increment_skip_size
    @skip_size += 1
  end

  def un_rotate
    @list.rotate!(-@rotations)
  end
end