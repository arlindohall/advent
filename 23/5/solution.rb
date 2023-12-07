def solve(input = read_input) =
  SeedMap.new(input).then { |sm| [sm.lowest_location] }

class SeedMap
  def initialize(text)
    @text = text
  end

  def lowest_location
    locations.map(&:to_i).min
  end

  def lowest_range
    range_locations.map(&:to_i).min
  end

  def seed_ranges
    seeds.map(&:to_i).each_slice(2).to_a.map { |range| SeedRanges.new([range]) }
  end

  def seeds
    @text
      .split("\n\n")
      .first
      .split(": ")
      .second
      .split
      .map(&:to_i)
      .map { |i| Seed.new(i) }
  end

  def locations
    seeds.map { |seed| convert(seed) }.map(&:to_i)
  end

  def range_locations
    seed_ranges.map { |seed| convert(seed) }
  end

  memoize def conversions
    @text.split("\n\n").drop(1).map { |block| Conversion.new(block) }
  end

  def convert(seed)
    conversions.each { |conversion| seed = conversion.apply(seed) }
    seed
  end
end

class Conversion
  def initialize(block)
    @block = block
  end

  def name
    @block.split("\n").first
  end

  def ranges
    @block.split("\n").drop(1).map { |line| ConversionRange.new(line) }
  end

  def apply(seed)
    ranges_for_debug = ranges.map { |r| [r.source_range, r.dest_start] }
    _debug("applying conversion", name, seed, ranges_for_debug)
    puts @block
    seed.convert(ranges) #.tap { |converted| _debug("converted", converted) }
  end
end

class ConversionRange
  def initialize(line)
    @line = line
  end

  def dest_start
    @line.split.first.to_i
  end

  def source_start
    @line.split.second.to_i
  end

  def source_range
    source_start..(@line.split.last.to_i + source_start)
  end

  def accept?(seed)
    seed.overlap?(source_range)
  end
end

class Seed
  def initialize(int)
    @int = int
  end

  def overlap?(range)
    range.include?(@int)
  end

  def convert(ranges)
    ranges.each do |range|
      if range.accept?(self)
        return Seed.new(@int - range.source_start + range.dest_start)
      end
    end

    return self
  end

  def to_i
    @int
  end
end

class SeedRanges
  def initialize(ranges)
    @ranges = ranges
  end

  def overlap?(range)
    @ranges.any? do |start, size|
      sub_range = (start.to_i..(start.to_i + size.to_i))
      range.include?(start.to_i) || range.include?(start.to_i + size.to_i) ||
        sub_range.include?(range.first) || sub_range.include?(range.last)
    end
  end

  def convert(conversion_ranges)
    @ranges
      .flat_map do |start, size|
        convert_one_range(start, size, conversion_ranges)
      end
      .then { |ranges| SeedRanges.new(ranges) }
  end

  def convert_one_range(start, size, conversion_ranges)
    SeedRangeConversionStep.new(start, size, conversion_ranges).convert
  end

  def to_i
    @ranges.map { |start, finish| start }.min
  end
end

class SeedRangeConversionStep
  def initialize(start, size, conversion_ranges)
    @start = start
    @size = size
    @conversion_ranges = conversion_ranges
  end

  def convert
    @cursor = @start
    @result = []

    save_one_range until @cursor >= @start + @size

    @result
  end

  def save_one_range
    # _debug("saving one range", @cursor, @start, @size)
    if in_range?
      @result << mapped_range_from_current_cursor
    else
      @result << unmapped_range_until_next_range_match
    end
  end

  def in_range?
    @conversion_ranges.any? { |range| range.accept?(Seed.new(@cursor)) }
  end

  def current_range
    @conversion_ranges.find { |range| range.accept?(Seed.new(@cursor)) }
  end

  def unmapped_range_until_next_range_match
    next_ranges =
      @conversion_ranges.filter { |range| range.source_start > @cursor }

    if next_ranges.empty?
      # _debug("no mapping, keeping", @cursor, @size)
      old_cursor, @cursor = @cursor, @cursor + @size
      return old_cursor, @size
    end

    next_range = next_ranges.min_by { |range| range.source_start }

    map_range(next_range, next_range.source_start - 1)
  end

  def mapped_range_from_current_cursor
    end_of_range =
      current_range.source_start + current_range.source_range.size - 1
    end_of_input = @start + @size - 1

    # _debug("mapping range for current cursor", end_of_range:, end_of_input:)
    if end_of_range > end_of_input
      map_range(current_range, end_of_input)
    else
      map_range(current_range, end_of_range)
    end
  end

  def map_range(range_mapping, input_end)
    shift = range_mapping.dest_start - range_mapping.source_start
    old_cursor, @cursor = @cursor, input_end + 1

    # _debug("mapping range", range_mapping:, old_cursor:)
    # _debug("mapping range (2)", cursor: @cursor, shift:, input_end:)
    [old_cursor + shift, input_end - old_cursor + 1]
  end
end
