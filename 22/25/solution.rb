class Bob
  def initialize(text)
    @text = text
  end

  def total_fuel
    to_snafu(snafu_total)
  end

  def snafu_total
    snafu_numbers.map(&:translate).sum
  end

  def to_snafu(num)
    NormalNumber.new(num).translate
  end

  def snafu_numbers
    @text.split("\n").map { |num| SnafuNumber.new(num) }
  end
end

class SnafuNumber
  def initialize(number)
    @number = number
  end

  def translate
    digits.each_with_index.map { |digit, idx| translate_digit(digit, idx) }.sum
  end

  def digits
    @number.chars
  end

  def translate_digit(digit, idx)
    5**place(idx) *
      case digit
      when "1"
        1
      when "2"
        2
      when "0"
        0
      when "-"
        -1
      when "="
        -2
      end
  end

  def place(idx)
    digits.length - idx - 1
  end
end

class NormalNumber
  def initialize(number)
    @number = number
  end

  def translate
    return @result if @result

    @place = 0
    @result = []

    next_place until all_divided?

    @result = @result.reverse.join
  end

  def all_divided?
    @number == 0
  end

  def next_place
    @result << translate_digit
    @place += 1

    @number += 2
    @number /= 5
  end

  def translate_digit
    case @number % 5
    when 0
      "0"
    when 1
      "1"
    when 2
      "2"
    when 3
      "="
    when 4
      "-"
    end
  end

  def place_value
    5**@place
  end
end

def test
  numbers = <<~NUMBERS
  1               1
  2               2
  3               1=
  4               1-
  5               10
  6               11
  7               12
  8               2=
  9               2-
  10              20
  15              1=0
  20              1-0
  2022            1=11-2
  12345           1-0---0
  314159265       1121-1110-1=0
  NUMBERS

  numbers.lines.each do |line|
    normal, snafu = line.split
    normal_obj = NormalNumber.new(normal.to_i)
    snafu_obj = SnafuNumber.new(snafu)

    assert_equals!(normal_obj.translate, snafu)
    assert_equals!(snafu_obj.translate, normal.to_i)
  rescue StandardError
    puts line
    raise
  end

  :success
end

def solve(input = read_input)
  Bob.new(input).total_fuel
end
