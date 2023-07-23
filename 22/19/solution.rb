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
      _debug(number:, max_found:, state:) if (@i += 1) % 1000 == 0
      @queue += state.calculate_next_states(self)
    end

    max_found
  end

  def initial_state(time)
    State[
      time: time,
      ore: 1,
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
    next_states = []

    if time >= 0
      # I don't understand the ore > 0 here, why would you not
      # build if you don't have any ore
      if blueprint.max_ore > ore_robots && ore > 0
        next_states << blueprint.plans[:ore].schedule_build(self)
      end
      if blueprint.max_clay > clay_robots && ore > 0
        next_states << blueprint.plans[:clay].schedule_build(self)
      end
      if blueprint.max_obsidian > obsidian_robots && ore > 0 && clay > 0
        next_states << blueprint.plans[:obsidian].schedule_build(self)
      end
      if ore > 0 && obsidian > 0
        next_states << blueprint.plans[:geode].schedule_build(self)
      end
    end

    next_states.filter { |state| state.time >= 0 }
  end

  def cannot_beat(amount)
    ((time * (time + 1)) / 2) <= amount
  end
end

class Robot
  shape :type, :costs

  def schedule_build(state)
    time = time_until_build(state)

    # _debug(type:, time:, state:)
    State[
      time: state.time - time,
      ore: state.ore - ore_cost + (time * state.ore_robots),
      clay: state.clay - clay_cost + (time * state.clay_robots),
      obsidian: state.obsidian - obsidian_cost + (time * state.obsidian_robots),
      geode: state.geode + (time * state.geode_robots),
      ore_robots: state.ore_robots + ore_robots_built,
      clay_robots: state.clay_robots + clay_robots_built,
      obsidian_robots: state.obsidian_robots + obsidian_robots_built,
      geode_robots: state.geode_robots + geode_robots_built
    ]
  end

  def time_until_build(state)
    [
      (
        if ore_cost <= state.ore
          0
        elsif state.ore_robots == 0
          Float::INFINITY
        else
          ((ore_cost - state.ore).to_f / state.ore_robots).ceil
        end
      ),
      (
        if clay_cost <= state.clay
          0
        elsif state.clay_robots == 0
          Float::INFINITY
        else
          ((clay_cost - state.clay).to_f / state.clay_robots).ceil
        end
      ),
      (
        if obsidian_cost <= state.obsidian
          0
        elsif state.obsidian_robots == 0
          Float::INFINITY
        else
          ((obsidian_cost - state.obsidian).to_f / state.obsidian_robots).ceil
        end
      )
    ].max + 1
  end

  %i[ore clay obsidian geode].each do |type|
    define_method("#{type}_robots_built") { type == self.type ? 1 : 0 }

    define_method("#{type}_cost") { costs[type] || 0 }
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
