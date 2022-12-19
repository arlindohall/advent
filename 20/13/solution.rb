
class BusSchedule < Struct.new(:notes)
  def answer
    earliest_bus * first_option(earliest_bus)
  end

  def earliest_bus
    busses.min_by { |bus| first_option(bus) }
  end

  def first_option(bus)
    bus - (departure % bus)
  end

  def first_alignment
    chinese_remainder % big_m
  end

  def chinese_remainder
    chinese_remainder_terms.map { |term| term.reduce(&:*) % big_m }.sum
  end

  def chinese_remainder_terms
    crt_inputs.map { |m, a| [-a, b(m), little_m(m)] }
  end

  def crt_inputs
    bus_with_time.each_with_index
      .reject { |m, a| m.zero? }
      .map { |m, a| [m, a % m] }
  end

  # b_i * M_i / m_i === 1 (mod m_i)
  def b(m)
    b = 1
    until (b * little_m(m)) % m == 1
      raise "No solution for b(#{m})" if b > m
      b += 1
    end

    b
  end

  def little_m(m)
    big_m / m
  end

  def big_m
    crt_inputs.map(&:first).reduce(&:*)
  end

  def busses
    bus_with_time.reject(&:zero?)
      .reject(&:zero?)
  end

  def bus_with_time
    notes.split.last.split(",")
      .map(&:to_i)
  end

  def departure
    notes.split.first.to_i
  end
end

def test
  [
    read_example,           1068781,
    "a 17,x,13,19",         3417,
    "a 67,7,59,61",         754018,
    "a 67,x,7,59,61",       779210,
    "a 67,7,x,59,61",       1261476,
    "a 1789,37,47,1889",    1202161486,
  ].each_slice(2) do |i,o|
    actual = BusSchedule.new(i).first_alignment
    return [i,o,actual] unless actual == o
  end
  :success
end

def solve
  [BusSchedule.new(read_input).answer, BusSchedule.new(read_input).first_alignment]
end