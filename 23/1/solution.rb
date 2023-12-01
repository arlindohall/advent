def solve =
  Trebuchet
    .new(read_input)
    .then { |input| [input.calibration_sum, input.spelled_sum] }

class Trebuchet
  def initialize(input)
    @input = input
  end

  def calibration_sum
    calibration_values.sum
  end

  def spelled_sum
    spelled_values.sum
  end

  def calibration_values
    CalibrationValues.new(lines).compute
  end

  def spelled_values
    CalibrationValues.new(lines, SpelledSum).compute
  end

  def lines
    @input.split("\n")
  end
end

class CalibrationValues
  def initialize(lines, value_class = CalibrationValue)
    @lines = lines
    @value_class = value_class
  end

  def compute
    @lines.map { |it| @value_class.new(it).compute }
  end
end

class CalibrationValue
  def initialize(line)
    @line = line
  end

  def compute
    [first_digit, last_digit].join.to_i
  end

  def first_digit
    @line.scan(/\d/).first
  end

  def last_digit
    @line.scan(/\d/).last
  end
end

class SpelledSum
  def initialize(line)
    @line = line
  end

  def compute
    [first_digit, last_digit].map { |d| convert(d).to_s }.join.to_i
  end

  def digits
    DigitMatcher.new(@line).digits
  end

  def first_digit
    digits.first
  end

  def last_digit
    digits.last
  end

  def convert(digit)
    case digit
    when "one"
      1
    when "two"
      2
    when "three"
      3
    when "four"
      4
    when "five"
      5
    when "six"
      6
    when "seven"
      7
    when "eight"
      8
    when "nine"
      9
    when "zero"
      0
    else
      digit
    end
  end
end

class DigitMatcher
  def initialize(line)
    @line = line
  end

  def digits
    @line
      .size
      .times
      .map { |start| @line.match(digit, start).to_s }
      .compact
      .reject(&:empty?)
  end

  def digit
    /
          \d |
          one |
          two |
          three |
          four |
          five |
          six |
          seven |
          eight |
          nine |
          zero
      /x
  end
end
