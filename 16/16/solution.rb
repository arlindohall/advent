

class Data
  def initialize(text)
    @text = text
  end

  def checksum
    Checksum.new(@text).sum
  end

  def fill(size)
    until fulfilled?(size)
      puts "Filling data desired=#{size}, size=#{@text.size}"
      @text = step
    end

    @text = @text[...size]

    self
  end

  def fulfilled?(size)
    @text.length >= size
  end

  def step
    @text + "0" + flipped
  end

  def flipped
    reversed.chars.map do |char|
      case char
      when "0"
        "1"
      when "1"
        "0"
      else
        raise "Unexpected character #{char}"
      end
    end.join
  end

  def reversed
    @text.reverse
  end
end

class Checksum
  def initialize(data)
    @data = data
  end

  def sum
    while @data.size.even?
      halve_data
    end
    @data
  end

  def halve_data
    @data = pairs.map{|pr| sum_one(pr)}.join
  end

  def pairs
    @data.chars.each_slice(2)
  end

  def sum_one(pair)
    pair.first == pair.last ? "1" : "0"
  end
end

@example = Data.new("10000").fill(20)
@input = Data.new("11100010111110100").fill(272)

# This will take too long, to create 35M of data and collapse it, but I'll try
# @part2 = Data.new("11100010111110100").fill(35651584)