
require 'set'

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
    puts risk_level
    puts fastest_path
  end

  def geologic_index(x, y)
    @geologic_index ||= {}
    return @geologic_index[[x,y]] if @geologic_index.include?([x,y])

    if x == 0
      @geologic_index[[x,y]] ||= mod(y * 48271)
    elsif y == 0
      @geologic_index[[x,y]] ||= mod(x * 16807)
    else
      @geologic_index[[x,y]] ||= mod(erosion_level(x, y-1) * erosion_level(x-1, y))
    end
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
    @times = {}
    @queue = [PathState.new(0, 0, 0, :torch)]

    @i = 0
    while @queue.any?
      @i += 1
      p [@i, @queue.size, @times.size] if @i % 10_000 == 0
      prune_queue if @i % 100_000 == 0
      visit_state
    end

    @times[@target][:torch]
  end

  def prune_queue
    @queue = @queue.filter { |state| is_improvement?(state) }
  end

  def visit_state
    @state = @queue.shift
    return if !is_improvement?(@state)

    @times[@state.location] ||= {}
    @times[@state.location][@state.equip] = [
      @state.time,
      @times[@state.location][@state.equip],
    ].compact
     .min

    possible_moves.each { |move|
      @queue << move
    }
  end

  def possible_moves
    neighbors(*@state.location).flat_map { |neighbor|
      possible_tools(neighbor).map { |tool|
        PathState.new(*neighbor, @state.time + time_to(neighbor, tool), tool)
      }
    }.filter { |state|
      is_improvement?(state)
    }
  end

  def possible_tools(location)
    tools_for(type_name(*location)).to_set & tools_for(type_name(*@state.location)).to_set
  end

  def time_to(location, tool)
    tool == @state.equip ? 1 : 8
  end

  def is_improvement?(state)
    have_not_visited?(state) ||
      faster_than_best_visit?(state)
  end

  def have_not_visited?(state)
    !@times.include?(state.location) ||
      !@times[state.location].include?(state.equip)
  end

  def faster_than_best_visit?(state)
    @times[state.location][state.equip] > state.time
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
    xbound, ybound = @bounds
    y >= 0 && x >= 0 && x <= xbound && y <= ybound
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

  # todo: something isn't right, the printed board is *slightly* off
  # but only to the right of the target and below the target
  def dump
    puts to_s
  end
end

def test_cave
  Cave.new(510, [10, 10], [20, 20])
end

def test
  test_cave.solve
end

def solve
  Cave.new(4080, [14, 785], [20, 800]).solve
end