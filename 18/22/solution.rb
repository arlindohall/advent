
require 'set'

require_relative '../../lib/grid'

PathState = Struct.new(:x, :y, :time, :equip)

class PathState
  def location
    [x, y]
  end

  def unique_key
    [x, y, equip]
  end

  def to_s
    "(#{x}, #{y}) #{time}/#{equip})"
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
    puts [risk_level, fastest_path]
  end

  def geologic_index(x, y)
    @geologic_index ||= {}
    return @geologic_index[[x,y]] if @geologic_index.include?([x,y])

    if x == 0
      @geologic_index[[x,y]] ||= mod(y * 48271)
    elsif y == 0
      @geologic_index[[x,y]] ||= mod(x * 16807)
    elsif [x,y] == @target
      @geologic_index[[x,y]] ||= 0
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
    @time = 0
    @times = {
      [0,0] => { torch: 0 }
    }
    @priority_queue = {
      0 => [PathState.new(0, 0, 0, :torch)]
    }

    until found_target?
      assert_priority_queue
      visit_priority
      @time += 1
    end

    drain_queue

    @times[@target][:torch]
  end

  def drain_queue
    until @priority_queue.empty?
      assert_priority_queue
      visit_priority
      @time += 1
    end
  end

  def found_target?
    @times.include?(@target) && @times[@target].include?(:torch)
  end

  def assert_priority_queue
    p [@time, @priority_queue.size, @priority_queue[@time]&.size] #if @time % 10 == 0
    raise "Expected queue=#{@priority_queue.keys.min}" \
      "to be strictly older than time=#{@time}" unless @priority_queue.keys.min >= @time
  end

  def visit_priority
    queue_by_next_time
      .uniq
      .flat_map { |state| next_states(state) }
      .uniq
      .each { |state| visit(state) }
  end

  def queue_by_next_time
    @priority_queue.delete(@time) || []
  end

  def next_states(state)
    next_locations(state)
      .flat_map { |x, y| valid_tools(x, y, state).map { |name| [[x,y], name] } }
      .map { |loc, equip| PathState.new(*loc, time_to(state, loc, equip), equip) }
      .reject { |new_state| new_state == state }
  end

  def valid_tools(x, y, state)
    tools_for(type_name(x, y)).to_set & tools_for(type_name(*state.location)).to_set
  end

  def time_to(state, loc, equip)
    state.time + travel_time(state, loc) + equip_time(state, equip)
  end

  def travel_time(state, loc)
    state.location == loc ? 0 : 1
  end

  def equip_time(state, equip)
    state.equip == equip ? 0 : 7
  end

  def visit(state)
    return unless faster_than_current?(state)
    return if slower_than_answer?(state)
    @priority_queue[state.time] ||= []
    @priority_queue[state.time] << state

    @times[state.location] ||= {}
    @times[state.location][state.equip] ||= state.time
  end

  def faster_than_current?(state)
    return true unless @times.include?(state.location)
    return true unless @times[state.location].include?(state.equip)

    @times[state.location][state.equip] > state.time
  end

  def slower_than_answer?(state)
    return false unless found_target?
    state.time > @times[@target][:torch]
  end

  def max_possible_time
    @max_possible_time ||= @target.sum + @target.map { |c| c * 7}.sum
  end

  def next_locations(state)
    neighbors(*state.location) + [state.location]
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

def test_cave
  Cave.new(510, [10, 10], [15, 15])
end

def test
  test_cave.solve
end

def solve
  # answer: 1087 <- too high
  # answer: 1075 <- too low
  # answer: 1082 <- too high
  Cave.new(4080, [14, 785]).solve
end