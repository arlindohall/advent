

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
    while @data.size.even?
      puts "Stepping down size=#{@data.size}"
      halve_data
    end
    @data.map(&:to_s).join
  end

  def halve_data
    @data = pairs.map{|pr| sum_one(pr)}
  end

  def pairs
    @data.each_slice(2)
  end

  def sum_one(pair)
    pair.first == pair.last ? 1 : 0
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
@part2 = Data.new("11100010111110100").fill(35651584)