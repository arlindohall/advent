def solve =
  OctopusGrid.parse(read_input).then { |it| [it.dup.after, it.dup.first_sync] }

class OctopusGrid
  attr_reader :octopi, :flashes
  def initialize(octopi)
    @octopi = octopi
  end

  def after(n = 100)
    n.times { update! }
    flashes
  end

  def first_sync
    i = 0
    loop do
      update!
      i += 1
      return i if octopi.values.all?(0)
    end
  end

  def update!
    @octopi = increment
    @octopi = flash until octopi.values.none?(10)

    @flashes ||= 0
    @flashes += octopi.values.count(11)
    @octopi = octopi.transform_values { |v| v == 11 ? 0 : v }
  end

  def increment
    octopi.keys.map { |loc| increment_at(loc) }.to_h
  end

  def increment_at(location)
    [location, octopi[location] + 1]
  end

  def flash
    octopi.map { |loc, val| [loc, val >= 10 ? 11 : flash_at(loc)] }.to_h
  end

  def flash_at(location)
    [
      10,
      octopi[location] +
        neighbors(location).map { |other| octopi[other] }.count(10)
    ].min
  end

  def neighbors(location)
    x, y = location
    [
      [x - 1, y - 1],
      [x - 1, y],
      [x - 1, y + 1],
      [x, y - 1],
      [x, y + 1],
      [x + 1, y - 1],
      [x + 1, y],
      [x + 1, y + 1]
    ]
  end

  def _debug
    10.times do |y|
      10.times do |x|
        print " "
        print(octopi[[x, y]])
      end
      puts
    end
  end

  def self.parse(text)
    new(
      text
        .split
        .each_with_index
        .flat_map do |row, y|
          row.chars.each_with_index.map { |oct, x| [[x, y], oct.to_i] }
        end
        .to_h
    )
  end
end
