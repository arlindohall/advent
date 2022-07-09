
class Firewall
  def initialize(filters)
    @filters = filters
  end

  def self.parse(text)
    new(text.strip.lines.map(&:strip).map{|f| Filter.parse(f)})
  end

  def solve
    [severity(0), minimum_delay]
  end

  def minimum_delay
    (0..).lazy
      .filter{|t| !caught_at?(t)}
      .first
  end

  def severity(time)
    caught_at(time).map(&:severity).sum
  end

  def positions_at(time)
    @filters.each do |f|
      p [f.depth, f.position(time)]
    end
  end

  def caught_at(time)
    @filters.select{|f| f.caught(time)}
  end

  def caught_at?(time)
    @filters.any?{|f| f.caught(time)}
  end
end

class Filter
  attr_reader :depth
  def initialize(depth, range)
    @depth = depth
    @range = range
  end

  def self.parse(text)
    depth, range = text.split(': ').map(&:to_i)
    new(depth, range)
  end

  def caught(start_time)
    position(start_time + travel_time) == 0
  end

  # How long it takes to reach this depth
  def travel_time
    @depth
  end

  def position(time)
    moves(time) >= @range ?
      @range - 1 - moves(time) % @range :
      moves(time)
  end

  def moves(time)
    time % (@range * 2 - 2)
  end

  def severity
    @depth * @range
  end
end

@example = <<-filter
0: 3
1: 2
4: 4
6: 4
filter

@input = <<-filter
0: 3
1: 2
2: 9
4: 4
6: 4
8: 6
10: 6
12: 8
14: 5
16: 6
18: 8
20: 8
22: 8
24: 6
26: 12
28: 12
30: 8
32: 10
34: 12
36: 12
38: 10
40: 12
42: 12
44: 12
46: 12
48: 14
50: 14
52: 8
54: 12
56: 14
58: 14
60: 14
64: 14
66: 14
68: 14
70: 14
72: 14
74: 12
76: 18
78: 14
80: 14
86: 18
88: 18
94: 20
98: 18
filter