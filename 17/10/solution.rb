
class Ring
  APPEND_INSTRUCTIONS = [17, 31, 73, 47, 23]

  def initialize(list, lengths)
    @list = list
    @instructions = lengths
    @skip_size = 0
    @rotations = 0
  end

  def solve
    [
      dup.one_round_only.take(2).reduce(&:*),
      dup.hex_hash
    ]
  end

  def dup
    Ring.new(@list.dup, @instructions.dup)
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
    @instructions.map(&:to_s)
      .join(',')
      .bytes
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

@example = [
  [0, 1, 2, 3, 4],
  [3, 4, 1, 5],
]

@input = [
  0.upto(255).to_a,
  [120,93,0,90,5,80,129,74,1,165,204,255,254,2,50,113],
]