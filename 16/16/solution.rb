

class Data
  def initialize(text)
    @text = text.chars.map(&:to_i)
  end

  def checksum
    Checksum.new(@text).sum
  end

  def fill(size)
    until fulfilled?(size)
      puts "Stepping desired=#{size} size=#{@text.size}"
      step!
    end

    @text = @text[...size]

    self
  end

  def fulfilled?(size)
    @text.length >= size
  end

  def step!
    @text << 0
    flipped do |f|
      @text << f
    end
  end

  def flipped
    reversed do |bit|
      yield(1-bit)
    end
  end

  def reversed
    for i in (@text.length-2).downto(0)
      yield(@text[i])
    end
  end
end

class Checksum
  def initialize(data)
    @data = data
  end

  def sum
    result = (@data.size/group_size).times.to_a.map{nil}
    index = 0
    while index < @data.size
      sum = @data[index...index+group_size].sum
      result[index/group_size] = sum.even? ? 1 : 0
      index += group_size
    end

    result.map(&:to_s).join
  end

  def group_size
    @group_size ||= begin
      size = @data.size
      group_size = 1
      while size.even?
        size = size/2
        group_size *= 2
      end
      group_size
    end
  end
end

@example = Data.new("10000").fill(20)
@input = Data.new("11100010111110100").fill(272)

<<-EXPLANATION
This has yet to finish for me so I can time it using strings.
But with this implementation using lists, it's maybe 30 seconds.

That's because of the string cache limit, and because I used blocks/yield
to reverse the arrays instead of map/reverse which would copy them.
EXPLANATION
def part2
  Data.new("11100010111110100").fill(35651584).checksum
end