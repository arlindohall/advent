
class XmasData < Struct.new(:text, :preamble_length)
  def initialize(text, preamble_length: 25)
    self.text = text
    self.preamble_length = preamble_length
  end

  def first_invalid
    preamble_length.upto(numbers.size - 1) do |idx|
      return numbers[idx] unless window(idx).valid?
    end

    raise "No invalid numbers found"
  end

  def encryption_weakness
    contiguous_region.minmax.sum
  end

  def contiguous_region
    target = first_invalid
    0.upto(numbers.size - 2) do |idx|
      range = idx + 1
      until numbers[idx..range].sum > target || range >= numbers.size
        return numbers[idx..range] if numbers[idx..range].sum == target
        range += 1
      end
    end
  end

  def window(idx)
    Window.new(numbers[idx-25...idx], numbers[idx])
  end

  def numbers
    @numbers ||= text.strip.split("\n").map(&:to_i)
  end
end

class Window < Struct.new(:numbers, :target)
  def valid?
    numbers.any? { |num| (numbers - [num]).include?(target - num) }
  end
end

def solve
  [XmasData.new(read_input).first_invalid, XmasData.new(read_input).encryption_weakness]
end