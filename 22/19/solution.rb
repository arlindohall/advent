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

  def max_geodes
    max = 0
    queue = [{ time: 24, robots: { ore: 1 }, resources: {} }]
    i = 0

    until queue.empty?
      state = queue.shift
      queue += next_states(state, max)
      max = [max, state[:resources][:geodes] || 0].max
      _debug(queue: queue.size, max:, state:) if i % 1000 == 0
      i += 1
    end

    max
  end

  def next_states(state, max_geodes)
    return [] if cannot_outproduce?(state, max_geodes)

    robot_types
      .flat_map { |type, robot| next_state(state, type, robot) }
      .compact
      .uniq
  end

  def next_state(state, type, robot)
    # _debug(state:, type:, robot:)
    return wait(state) if cannot_afford?(state, robot)

    {
      time: state[:time] - 1,
      robots: update_robots(state, robot),
      resources: update_resources(state),
      scheduled: type
    }
  end

  def wait(state)
    state.merge(time: state[:time] - 1, resources: update_resources(state))
  end

  def update_robots(state, robot)
    scheduled = state[:scheduled]
    # _debug("robots", state: state[:robots], type: robot.type)
    state[:robots].merge(
      robot.type =>
        (state[:robots][robot.type] || 0) + (robot.type == scheduled ? 1 : 0)
    )
  end

  def update_resources(state)
    # _debug("updating resources", state:)
    all_resources
      .map { |r| [r, (state[:resources][r] || 0) + (state[:robots][r] || 0)] }
      .to_h
  end

  memoize def all_resources
    robot_types.map { |type, _robot| type }
  end

  def cannot_afford?(state, robot)
    # _debug(resources: state[:resources], robot: robot)
    robot.costs.any? { |name, amount| (state[:resources][name] || 0) < amount }
  end

  def cannot_outproduce?(state, max_geodes)
    (state[:resources][:geodes] || 0) + max_producible(state[:time]) <=
      max_geodes
  end

  def max_producible(time)
    # sum i = 0 to n of i
    time * (time + 1) / 2
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
