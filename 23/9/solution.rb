def solve(input = read_input) =
  OasisScan.new(input).then { |it| [it.extrapolated_sum, it.backward_sum] }

class OasisScan
  def initialize(text)
    @text = text
  end

  def extrapolated_sum
    next_values.sum
  end

  def backward_sum
    prev_values.sum
  end

  def next_values
    readings.map { |r| r.next_value }
  end

  def prev_values
    readings.map { |r| r.prev_value }
  end

  def readings
    @text.lines.map { |line| Reading.parse(line) }
  end
end

class Reading
  def self.parse(line)
    new(line.strip.split.map { |v| v.to_i })
  end

  attr_reader :values
  def initialize(values)
    @values = values
  end

  def next_value
    return 0 if values.all? { |v| v.zero? }

    derivative.next_value + values.last
  end

  def prev_value
    return 0 if values.all? { |v| v.zero? }

    values.first - derivative.prev_value
  end

  def derivative
    Reading.new(
      (values.size - 1).times.map { |idx| values[idx + 1] - values[idx] }
    )
  end
end
