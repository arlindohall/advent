
require_relative '../../lib/grid'

class PathState
  attr_reader :time, :equip

  def initialize(x, y, time, equip)
    @x, @y = x, y
    @time = time
    @equip = equip
  end

  def location
    [@x, @y]
  end

  def unique_key
    [@x, @y, @equip]
  end
end

class Cave
  include Coordinates

  def initialize(depth, target, bounds = nil)
    @depth = depth
    @target = target
    @bounds = bounds || target
  end

  def solve
    [risk_level, fastest_path]
  end

  # Todo: allow this to extend past target by using a hash map
  def geologic_index(x, y)
    return @geologic_index[[x,y]] if @geologic_index&.include?([x,y])

    x,y = @bounds
    @geologic_index = {}

    0.upto(x) { |x| @geologic_index[[x,0]] ||= mod(x * 16807) }
    0.upto(y) { |y| @geologic_index[[0,y]] ||= mod(y * 48271) }

    1.upto(y) { |y|
      1.upto(x) { |x|
        @geologic_index[[x,y]] ||= mod(erosion_level(x, y-1) * erosion_level(x-1, y))
      }
    }

    @geologic_index[[x,y]]
  end

  def erosion_level(x, y)
    @erosion_level ||= {}
    @erosion_level[[x,y]] ||= mod(geologic_index(x,y) + @depth)
  end

  def type(x, y)
    erosion_level(x, y) % 3
  end

  def risk_level
    x, y = @target
    0.upto(y).flat_map { |y|
      0.upto(x).map { |x|
        type(x, y) unless [x,y] == @target
      }.compact
    }.sum
  end

  def mod(value)
    value % 20183
  end

  def fastest_path
    @queue = [PathState.new(0, 0, 0, :torch)]
    # TODO: Hash times by location + tool, because those are two different states
    @times = Hash.new(Float::INFINITY)

    @i = 0
    while @queue.any?
      @i += 1
      p [@i, @queue.size, @state] if @i % 10_000 == 0
      # p [@queue.map(&:time).uniq.sort] if @i % 10_000 == 0
      # p [@queue.map(&:location).map(&:first).minmax, @queue.map(&:location).map(&:last).minmax] if @i % 10_000 == 0
      add_possible_paths
    end

    @times.filter { |key, time| key[0..1] == @target }
      .values
      .min
  end

  def add_possible_paths
    @state = @queue.shift

    # Quit for this one if it's longer than the current solution or the current
    # best time to this spot
    return if @state.time >= @times[@state.unique_key] || @state.time >= @times[@target]
    @times[@state.unique_key] = @state.time
    @times[@state.location] = @state.time if @state.location == @target

    # TODO: Prune here instead of after, only add to queue if smaller than current largest
    options.filter { |state| state.time < @times[state.unique_key] }
      .each { |option| @queue << option }
  end

  def options
    neighbors(*@state.location).flat_map { |x,y|
      destination_type = type_name(x, y)
      tool = @state.equip

      possible_steps(@state.time, tool, destination_type, [x,y])
    }
  end

  def possible_steps(time_so_far, current_tool, destination_type, location)
    tool_combinations(current_tool, destination_type).map { |new_tool, equip_time|
      PathState.new(*location, equip_time + time_so_far, new_tool)
    }
  end

  def tool_combinations(current_tool, destination_type)
    tools_for(destination_type).map { |tool|
      [tool, tool == current_tool ? 1 : 8]
    }
  end

  def tools_for(type)
    case type
    when :rocky
      [:torch, :climbing]
    when :wet
      [:climbing, :neither]
    when :narrow
      [:torch, :neither]
    end
  end

  # for including Coordinates
  def in_bounds?(x, y)
    y >= 0 && x >= 0
  end

  def type_name(x, y)
    case type(x, y)
    when 0 then :rocky
    when 1 then :wet
    when 2 then :narrow
    end
  end

  def printable_type(x, y)
    case type(x, y)
    when 0 then '.' # rocky
    when 1 then '=' # wet
    when 2 then '|' # narrow
    end
  end

  def to_s
    x, y = @bounds
    0.upto(y).map { |y|
      0.upto(x).map { |x|
        [x,y] == [0,0] ? 'M' : (
          [x,y] == @target ? 'T' : printable_type(x, y)
        )
      }.join
    }.join("\n")
  end

  def dump
    puts to_s
  end
end

def solve
  puts Cave.new(4080, [14, 785]).solve
end