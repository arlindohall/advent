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
    @queue = PriorityQueue.new { |state| state[:geode] }
    queue.push(initial_state(time))

    until queue.empty?
      state = queue.shift
      @queue += calculate_next_states(state)
      if max_found < state[:geode]
        _debug("max_found", max_found:, state: state)
        @max_found = state[:geode]
      end
    end

    max_found
  end

  def calculate_next_states(state)
    next_states = []
    @i ||= 0

    return next_states if invalid(state)

    if max(:ore) > state[:ore_robots]
      next_states << plans[:ore].schedule_build(state)
    end

    if max(:clay) > state[:clay_robots]
      next_states << plans[:clay].schedule_build(state)
    end

    if max(:obsidian) > state[:obsidian_robots] && state[:clay_robots] > 0
      next_states << plans[:obsidian].schedule_build(state)
    end

    if state[:obsidian_robots] > 0
      next_states << plans[:geode].schedule_build(state)
    end

    next_states.compact.reject { |it| invalid(it) }
  end

  def invalid(state)
    return true if cannot_beat_best(state)
    state.values.any?(&:negative?)
  end

  def cannot_beat_best(state)
    best_possible(state) < max_found
  end

  def best_possible(state)
    time = state[:time]
    time * (time - 1) / 2
  end

  memoize def max(type)
    plans.values.map(&:costs).map { |it| it[type] || 0 }.max
  end

  def initial_state(time)
    {
      time: time,
      ore_robots: 1,
      ore: 1,
      clay_robots: 0,
      clay: 0,
      obsidian_robots: 0,
      obsidian: 0,
      geode_robots: 0,
      geode: 0
    }
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

class Robot
  shape :type, :costs

  def schedule_build(state)
    time_required = time_to_build(state)
    return unless time_required <= state[:time]

    next_state =
      state.merge(
        time: state[:time] - time_required,
        ore: state[:ore] - cost(:ore) + (time_required * state[:ore_robots]),
        clay:
          state[:clay] - cost(:clay) + (time_required * state[:clay_robots]),
        obsidian:
          state[:obsidian] - cost(:obsidian) +
            (time_required * state[:obsidian_robots]),
        geode: state[:geode] + (time_required * state[:geode_robots]),
        ore_robots: state[:ore_robots] + (type == :ore ? 1 : 0),
        clay_robots: state[:clay_robots] + (type == :clay ? 1 : 0),
        obsidian_robots: state[:obsidian_robots] + (type == :obsidian ? 1 : 0),
        geode_robots: state[:geode_robots] + (type == :geode ? 1 : 0)
      )
    # ensure
    #   if state[:time] > 0 && state[:ore_robots] == costs[:ore] &&
    #        state[:obsidian_robots] == costs[:obsidian]
    #     _debug(
    #       "geode",
    #       time_required:,
    #       robots: state[:geode_robots],
    #       next_state:,
    #       costs:
    #     )
    #   end
  end

  def time_to_build(state)
    elements_required.map { |type| time_to_get(state, type) }.max
  end

  def elements_required
    costs.keys
  end

  def time_to_get(state, type)
    return 1 if state[type] >= cost(type)
    ((cost(type) - state[type]).to_f / robots(state, type)).ceil.tap do |time|
      raise "Invalid time zero" if time.zero?
    end
  end

  def cost(type)
    costs[type] || 0
  end

  def robots(state, type)
    state["#{type}_robots".to_sym]
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
