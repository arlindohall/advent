$_debug = true

class Geodes
  shape :blueprints

  def quality_sum
    # blueprints.map { |it| it.quality_level }.sum
    blueprints.map { |it| [it.max_geodes, it.number] }
  end

  class << self
    def parse(text)
      new(blueprints: text.split("\n").map { |it| Blueprint.parse(it) })
    end
  end
end

class Blueprint
  shape :number, :plans

  def quality_level
    max_geodes * number
  end

  # Completely shamelessly stolen from https://todd.ginsberg.com/post/advent-of-code/2022/day19/
  # Trick was logic to skip building when we already have enough robots to make as much as we
  # will ever need.
  attr_reader :max_found, :queue
  def max_geodes(time = 24)
    @max_found = 0
    @queue = PriorityQueue.new { |state| state.geode }
    @queue.push(initial_state(time))

    @i = 0
    until queue.empty?
      state = queue.shift
      next if state.cannot_beat(max_found)

      @max_found = [max_found, state.geode].max
      next if state.time == 0

      if (@i += 1) % 10_000 == 0
        _debug(number:, max_found:, size: queue.size, state:)
      end
      next_states = state.calculate_next_states(self)
      @queue += next_states
    end

    max_found
  end

  def initial_state(time)
    State[
      time: time,
      ore: 0,
      clay: 0,
      obsidian: 0,
      geode: 0,
      ore_robots: 1,
      clay_robots: 0,
      obsidian_robots: 0,
      geode_robots: 0
    ]
  end

  %i[ore clay obsidian].each do |type|
    define_method("max_#{type}") do
      plans.map { |_name, plan| plan.costs[type] }.compact.max
    end
  end

  class << self
    def parse(text)
      number, plans, *_rest = text.split(":")
      plans = plans.split(".")
      new(
        number: number.split.second.to_i,
        plans: plans.map { |it| Robot.parse(it) }.hash_by(&:type)
      )
    end
  end
end

class State
  shape :time,
        :ore,
        :clay,
        :obsidian,
        :geode,
        :ore_robots,
        :clay_robots,
        :obsidian_robots,
        :geode_robots

  def calculate_next_states(blueprint)
    states = []

    if ore_robots < blueprint.max_ore
      states << blueprint.plans[:ore].build(self)
    end
    if clay_robots < blueprint.max_clay
      states << blueprint.plans[:clay].build(self)
    end
    if obsidian_robots < blueprint.max_obsidian && clay_robots > 0
      states << blueprint.plans[:obsidian].build(self)
    end
    states << blueprint.plans[:geode].build(self) if obsidian_robots > 0
    states = [grind_geode] if max_fulfilled?(blueprint)
    states = [run_out_the_clock] if has_geodes_but_cannot_build?(blueprint)

    states.compact
  end

  def has_geodes_but_cannot_build?(blueprint)
    return false unless geode > 0

    blueprint.plans[:geode].time_to_make(self) > time
  end

  def run_out_the_clock
    State[time: 0, geode: geode + (time * geode_robots)]
  end

  def grind_geode
    raise "Building max geodes with geode=#{geode} max_build=#{max_buildable_geodes}}"
    State[time: 0, geode: geode + max_buildable_geodes]
  end

  def cannot_beat(amount)
    max_buildable_geodes < amount
  end

  def max_buildable_geodes
    geode + ((time * (time + 1)) / 2)
  end

  def max_fulfilled?(blueprint)
    blueprint.plans[:geode].costs[:ore] <= ore_robots &&
      blueprint.plans[:geode].costs[:obsidian] <= obsidian_robots
  end

  def robots_for(type)
    send("#{type}_robots")
  end

  def merge(**params)
    other = dup
    params.each { |k, v| other.instance_variable_set("@#{k}", v) }

    other
  end
end

class Robot
  shape :type, :costs

  def build(state)
    return if cannot_build?(state)

    time_spent = time_to_make(state)
    return if time_spent > state.time

    ore_collected = time_spent * state.ore_robots
    clay_collected = time_spent * state.clay_robots
    obsidian_collected = time_spent * state.obsidian_robots
    geodes_collected = time_spent * state.geode_robots

    State[
      time: state.time - time_spent,
      ore: state.ore - ore_cost + ore_collected,
      clay: state.clay - clay_cost + clay_collected,
      obsidian: state.obsidian - obsidian_cost + obsidian_collected,
      geode: state.geode + geodes_collected,
      ore_robots: state.ore_robots + ore_robots_built,
      clay_robots: state.clay_robots + clay_robots_built,
      obsidian_robots: state.obsidian_robots + obsidian_robots_built,
      geode_robots: state.geode_robots + geode_robots_built
    ]
  end

  def cannot_build?(state)
    # _debug(state:, costs:)
    costs.keys.any? { |type| state.robots_for(type) < 1 }
  end

  %i[ore clay obsidian].each do |type|
    define_method("#{type}_cost") { costs[type] || 0 }
  end

  %i[ore clay obsidian geode].each do |type|
    define_method("#{type}_robots_built") { type == self.type ? 1 : 0 }
  end

  def time_to_make(state)
    max_needed =
      costs
        .map do |type, needed|
          next 0.0 if state[type] >= needed

          (needed - state[type]) / state.robots_for(type).to_f
        end
        .map(&:ceil)
        .max

    if max_needed == Float::INFINITY
      binding.pry
      raise "Takes infinity to build #{self.type} from state=#{state}"
    end
    # Time to get resources and then to build
    max_needed.to_i + 1
  end

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
