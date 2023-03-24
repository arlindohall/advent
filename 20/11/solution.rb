class Parser < Struct.new(:text)
  def seat_map
    SeatMap.new(
      text
        .split
        .each_with_index
        .flat_map do |line, y|
          line.chars.each_with_index.map do |char, x|
            case char
            when "L"
              [[x, y], "."]
            when "."
              nil
            when "#"
              [[x, y], "#"]
            end
          end
        end
        .compact
        .to_h
    )
  end
end

class SeatMap < Struct.new(:seats)
  def stable
    ptr = dup
    ptr = ptr.next_seat_map while ptr.next_seat_map != ptr

    ptr.taken
  end

  def relaxed
    SeatMapRelaxed.new(seats)
  end

  def taken
    seats.values.count("#")
  end

  def next_seat_map
    @next_seat ||=
      self.class.new(seats.map { |loc, st| next_seat(loc, st) }.to_h)
  end

  def next_seat(location, seat)
    if seat == "." && neighbors(location).count("#") == 0
      [location, "#"]
    elsif seat == "#" && crowded?(location)
      [location, "."]
    else
      [location, seat]
    end
  end

  def crowded?(location)
    neighbors(location).count("#") >= 4
  end

  def neighbors(location)
    x, y = location
    [
      [x - 1, y - 1],
      [x, y - 1],
      [x + 1, y - 1],
      [x - 1, y],
      [x + 1, y],
      [x - 1, y + 1],
      [x, y + 1],
      [x + 1, y + 1]
    ].map { seats[_1] }
  end
end

class SeatMapRelaxed < SeatMap
  def stable
    ptr = dup
    ptr = ptr.next_seat_map while ptr.next_seat_map != ptr

    ptr.taken
  end

  def _debug
    0.upto(height) do |y|
      0.upto(width) do |x|
        print case seats[[x, y]]
              when "#"
                "#"
              when "."
                "L"
              else
                "."
              end
      end
      puts
    end
  end

  def crowded?(location)
    neighbors(location).count("#") >= 5
  end

  def neighbors(location)
    visible[location].map { seats[_1] }
  end

  def visible
    @visible ||= seats.map { |loc, st| [loc, visible_from(loc)] }.to_h
  end

  def visible_from(location)
    [
      ->(x, y) { [x - 1, y - 1] },
      ->(x, y) { [x, y - 1] },
      ->(x, y) { [x + 1, y - 1] },
      ->(x, y) { [x - 1, y] },
      ->(x, y) { [x + 1, y] },
      ->(x, y) { [x - 1, y + 1] },
      ->(x, y) { [x, y + 1] },
      ->(x, y) { [x + 1, y + 1] }
    ].map { |increment| visible_seat(location, increment) }.compact
  end

  def visible_seat(location, increment)
    x, y = location
    x, y = increment[x, y]
    x, y = increment[x, y] until out_of_bounds?(x, y) || seats[[x, y]]

    return nil if out_of_bounds?(x, y)
    [x, y]
  end

  def out_of_bounds?(x, y)
    return true if x < 0
    return true if y < 0

    return true if x > width
    return true if y > height

    false
  end

  def width
    @width ||= seats.keys.map { _1[0] }.max
  end

  def height
    @height ||= seats.keys.map { _1[1] }.max
  end
end

def solve
  [
    Parser.new(read_input).seat_map.stable,
    Parser.new(read_input).seat_map.relaxed.stable
  ]
end
