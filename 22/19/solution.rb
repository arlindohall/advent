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
    bfs(24, { ore: 1 }, {}, [])
  end

  memoize def bfs(time, robots, resources, building_robots)
    @i ||= 0
    @i += 1
    _debug(time:, robots:, resources:, building_robots:) if @i % 10_000 == 0
    return resources[:geode] if time == 0

    max = 0
    possible_builds(robots, resources).each do |built, depleted_resources|
      updated_resources = update_resources(robots, depleted_resources)
      updated_builds = decrement_builds(building_robots, built)
      updated_robots = update_robots(robots, updated_builds)
      amount =
        bfs(
          time - 1,
          updated_robots,
          updated_resources,
          updated_builds.filter { |robot, time| time > 0 }
        )
      max = [max, amount].max
    end
    max
  end

  def possible_builds(robots, resources)
    builds = robot_types.values.map { |r| r.build(resources) }.compact

    builds += [[nil, resources]] if saving_up?(robots, resources)
    builds
  end

  def saving_up?(robots, resources)
    robot_types.keys.any? do |type|
      not_enough_to_build?(type, resources) && could_build?(type, robots)
    end
  end

  def not_enough_to_build?(type, resources)
    robot_types[type].costs.any? do |name, amount|
      (resources[name] || 0) < amount
    end
  end

  def could_build?(type, robots)
    robot_types[type].costs.all? do |name, count|
      (count == 0) || ((robots[name] || 0) > 0)
    end
  end

  def update_resources(robots, depleted_resources)
    robot_types
      .map do |type, robot|
        amount = robots[type] || 0
        amount += depleted_resources[type] if depleted_resources[type]

        [type, amount]
      end
      .to_h
  end

  def decrement_builds(building_robots, built)
    builds = building_robots.map { |robot, time| [robot, time - 1] }

    return builds if built.nil?

    builds + [[built, 1]]
  end

  def update_robots(robots, building_robots)
    robot_types
      .map do |type, robot|
        amount = robots[type] || 0
        amount +=
          building_robots.count { |robot, time| robot == type && time == 0 }

        [type, amount]
      end
      .to_h
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

  def build(resources)
    can_build?(resources) ? [type, deplete(resources)] : [nil, resources]
  end

  def can_build?(resources)
    costs.all? { |name, amount| (resources[name] || 0) >= amount }
  end

  def deplete(resources)
    resources.map { |name, amount| [name, amount - (costs[name] || 0)] }.to_h
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
