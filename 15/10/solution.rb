

RunLength = Struct.new(:count, :digit)
NumberChain = Struct.new(:string_repr)
class NumberChain
  def read_aloud
    run_length_encode.flat_map do |rl|
      [rl.count, rl.digit]
    end.join
  end

  def run_length_encode
    @index = @count = 0
    @run_lengths = []

    @digit = current_char
    advance

    while @index <= string_repr.length
      if current_char != @digit
        @run_lengths << RunLength[@count.to_s, @digit]
        @digit = current_char
        @count = 0
      end
      advance
    end

    @run_lengths
  end

  def advance
    @index += 1
    @count += 1
  end

  def current_char
    string_repr[@index]
  end
end

@input = "1321131112"

50.times do |i|
  puts "Running the #{i}th iteration..."
  @input = NumberChain.new(@input).read_aloud
end
