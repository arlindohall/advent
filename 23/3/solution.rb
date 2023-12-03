def solve(input = read_input) =
  GearRatio.new(input).then { |gr| [gr.part_sum, gr.gear_ratio_sum] }

class GearRatio
  def initialize(text)
    @text = text
  end

  def gear_ratio_sum
    gears.map { |g_loc| Gear.new(g_loc).calculate(numbers) }.sum
  end

  def part_sum
    part_numbers.map(&:number).sum
  end

  def part_numbers
    numbers.reject { |n| n.not_adjacent?(symbols) }
  end

  def symbols
    @symbols ||= symbol_locations.keys.to_set
  end

  def symbol_locations
    @symbol_locations ||=
      @text
        .split("\n")
        .each_with_index
        .flat_map do |line, row|
          line.chars.each_with_index.map do |ch, col|
            [[row, col], ch] if ch =~ /[^\d.]/
          end
        end
        .compact
        .to_h
  end

  def numbers
    @numbers ||=
      @text
        .split("\n")
        .each_with_index
        .flat_map { |line, r| numbers_on_row(r, line) }
  end

  def gears
    symbol_locations.keys.reject do |location|
      symbol_locations[location] != "*"
    end
  end

  def numbers_on_row(row, line = nil)
    line ||= @text.split("\n")[row]
    numbers = []
    col = 0

    col += Number.parse(line, row, col, numbers) until col >= line.length

    numbers
  end
end

class Number
  def self.parse(text, row, col, destination)
    if text[col] =~ /\d/
      number = Number.new(text[col..].to_i, [row, col])
      destination << number
      return number.length
    end

    1
  end

  attr_reader :number
  def initialize(number, coord)
    @number = number
    @row, @col = coord
  end

  def not_adjacent?(symbols)
    neighbors.none? { |nb| symbols.include?(nb) }
  end

  def neighbors
    above + below + ends
  end

  def above
    (@col - 1).upto(@col + length).map { |col| [@row - 1, col] }
  end

  def below
    (@col - 1).upto(@col + length).map { |col| [@row + 1, col] }
  end

  def ends
    [[@row, @col - 1], [@row, @col + length]]
  end

  def length
    @number.to_s.length
  end
end

class Gear
  def initialize(location)
    @location = location
    @row, @column = location
  end

  def calculate(numbers)
    neighbors = numbers.reject { |n| n.not_adjacent?([@location]) }

    return 0 unless neighbors.size == 2

    neighbors.first.number * neighbors.second.number
  end
end
