$_debug = true

class Geodes
  shape :blueprints

  def quality_sum
    blueprints.map { |it| it.quality_level }.sum
  end

  class << self
    def parse(text)
      new(blueprints: text.split("\n\n").map { |it| Blueprint.parse(it) })
    end
  end
end

class Blueprint
  shape :number, :robot_types

  def quality_level
    max_geodes * number
  end

  attr_reader :max_found, :queue
  def max_geodes(time = 24)
    @max_found = 0
    @queue = PriorityQueue.new { |state| state[:geode] }
    queue.push(initial_state(time))

    @queue += make_states(queue.shift) until queue.empty?

    max_found
  end

  def initial_state(time)
    {
      time: 24,
      ore_robots: 1,
      ore: 0,
      clay_robots: 0,
      clay: 0,
      obsidian_robots: 0,
      obsidian: 0,
      geode_robots: 0,
      geode: 0
    }
  end

  def make_states(state)
    @max_found = [max_found, state[:geode]].max

    return [] if cannot_outproduce_max?(state)
    return [] if state[:time] == 0

    @i ||= 0
    @i += 1
    if @i % 10_000 == 0
      _debug("searching state", size: queue.size, max_found:, state:)
    end

    states = []

    states << make_robot(:ore, state)
    states << make_robot(:clay, state)
    states << make_robot(:obsidian, state)
    states << make_robot(:geode, state)

    states.compact #.tap { |it| _debug("states for", old: state, new: it) }
  end

  memoize def resources
    %i[ore clay obsidian geode]
  end

  memoize def robots
    resources.map { |r| robot(r) }
  end

  memoize def robot(type)
    "#{type}_robots".to_sym
  end

  def make_robot(type, state)
    time_to_produce = time_for(type, state)
    return nil if time_to_produce > state[:time]
    return nil if robot_types[type].costs.keys.any? { |r| state[robot(r)] == 0 }

    state = state.dup

    # _debug("producing", time_to_produce:, state:)
    resources.each do |resource|
      state[resource] += time_to_produce * state[robot(resource)]
      state[resource] -= robot_types[type].costs[resource] || 0
    end

    # _debug("calculated resources, adding robot", state:)
    state[robot(type)] += 1
    state[:time] = state[:time] - time_to_produce

    # _debug("added robots", state:, time: state[:time])
    raise "negative value" if state.values.any? { |v| v < 0 }
    state
  end

  def time_for(type, state)
    needed =
      resources.filter_map do |cost|
        next nil unless robot_types[type].costs[cost]
        needed = (robot_types[type].costs[cost] || 0) - state[cost]
        [cost, [needed, 0].max]
      end

    # _debug("calculating time for", type:, needed:, state:)
    time_needed =
      needed
        .map do |type, needed|
          state[robot(type)].zero? ? 0 : (needed.to_f / state[robot(type)]).ceil
        end
        .max
  end

  def cannot_outproduce_max?(state)
    geode_robots = time = state[:time]

    max_producible =
      state[:geode] + (state[:geode_robots] * time) + (time * (time + 1) / 2)
    max_producible <= max_found
  end

  class << self
    def parse(text)
      number, *robot_types = text.split("\n")
      new(
        number: number.split.second.to_i,
        robot_types: robot_types.map { |it| Robot.parse(it) }.hash_by(&:type)
      )
    end
  end
end

class Robot
  shape :type, :costs

  class << self
    def parse(text)
      new(
        type: text.split.second.to_sym,
        costs:
          text
            .split
            .drop(4)
            .join(" ")
            .gsub(".", "")
            .split("and")
            .map do |it|
              it.split.then { |amount, name| [name.to_sym, amount.to_i] }
            end
            .to_h
      )
    end
  end
end
