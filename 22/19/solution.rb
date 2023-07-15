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

  attr_reader :max_found
  def max_geodes
    @max_found = 0
    queue = PriorityQueue.new { |state| weight(state) }
    queue.push(initial_state)

    queue += make_states(queue.shift) until queue.empty?
  end

  def weight(state)
    ore_value, clay_value, obsidian_value, geode_value = values

    state[:time] *
      (
        ore_value * state[:ore_robots] + clay_value * state[:clay_robots] +
          obsidian_value * state[:obsidian_robots] +
          geode_value * state[:geode_robots]
      )
    +(
      ore_value * state[:ore] + clay_value * state[:clay] +
        obsidian_value * state[:obsidian] + geode_value * state[:geodes]
    )
  end

  memoize def values
    geode_value = 1_000_000
    obsidian_value = geode_value / robot_types[:geode].costs[:obsidian] / 2

    clay_value = [obsidian_value / robot_types[:obsidian].costs[:clay] / 2].max

    ore_value = [
      geode_value / robot_types[:geode].costs[:ore] / 2,
      obsidian_value / robot_types[:obsidian].costs[:ore] / 2,
      clay_value / robot_types[:clay].costs[:ore] / 2
    ].max

    [ore_value, clay_value, obsidian_value, geode_value]
  end

  def initial_state(time = 24)
    {
      time: 24,
      ore_robots: 1,
      ore: 0,
      clay_robots: 0,
      clay: 0,
      obsidian_robots: 0,
      obsidian: 0,
      geode_robots: 0,
      geodes: 0
    }
  end

  def make_states(state)
    @i ||= 0
    @i += 1
    _debug("searching state", state:) if @i % 100_000 == 0

    @max_found = [max_found, state[:geodes]].max

    return [] if cannot_outproduce_max?(state)
    return [] if state[:time] == 0

    states = []

    states << make_robot(:geode, state) if can_produce?(:geode, state)
    states << make_robot(:obsidian, state) if can_produce?(:obsidian, state)
    states << make_robot(:clay, state) if can_produce?(:clay, state)
    states << make_robot(:ore, state) if can_produce?(:ore, state)
    states << build_nothing(state)

    states
  end

  def make_robot(type, state)
    new_state = state.dup

    buy_robot!(type, new_state)
    collect_resources!(new_state)
    build_robot!(type, new_state)

    new_state.merge!(time: state[:time] - 1)
  end

  def build_nothing(state)
    new_state = state.dup

    collect_resources!(new_state)

    new_state.merge!(time: state[:time] - 1)
  end

  def can_produce?(type, state)
    cost = robot_types[type].costs

    state[:ore] >= (cost[:ore] || 0) && state[:clay] >= (cost[:clay] || 0) &&
      state[:obsidian] >= (cost[:obsidian] || 0) &&
      state[:geodes] >= (cost[:geodes] || 0)
  end

  def buy_robot!(type, state)
    cost = robot_types[type].costs

    state[:ore] -= cost[:ore] if cost[:ore]
    state[:clay] -= cost[:clay] if cost[:clay]
    state[:obsidian] -= cost[:obsidian] if cost[:obsidian]
    state[:geodes] -= cost[:geodes] if cost[:geodes]
  end

  def collect_resources!(state)
    state[:ore] += state[:ore_robots]
    state[:clay] += state[:clay_robots]
    state[:obsidian] += state[:obsidian_robots]
    state[:geodes] += state[:geode_robots]
  end

  def build_robot!(type, state)
    state[:ore_robots] += 1 if type == :ore
    state[:clay_robots] += 1 if type == :clay
    state[:obsidian_robots] += 1 if type == :obsidian
    state[:geodes_robots] += 1 if type == :geodes
  end

  def cannot_outproduce_max?(state)
    geode_robots = state[:geode_robots]
    time = state[:time]

    max_producible = geode_robots * time + (time * (time + 1) / 2)
    max_producible < max_found
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
