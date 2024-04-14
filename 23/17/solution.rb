class CrucibleMap
  def initialize(text)
    @text = text
  end

  def optimal_heat_loss
    dijsktra.shortest_path
  end

  def dijsktra
    Dijkstra.new(map, bounds)
  end

  def map
    @text.split("\n").map { |row| row.chars.map(&:to_i) }
  end

  def bounds
    Bounds.new(map)
  end
end

class Dijkstra
  def initialize(map, bounds)
    @map = map
    @bounds = bounds
  end

  memoize def shortest_path
    setup

    until @next_steps.empty? # || shortest_next.distance > best_distance
      follow_one_step
    end

    approaches_to([@map.first.size - 1, @map.size - 1]).best
  end

  def follow_one_step
    if @next_steps[min_step].empty?
      @next_steps.delete(min_step)
      return
    end

    step = @next_steps[min_step].shift

    step.possible_steps(points, @bounds).each { |step| add_to_next_steps(step) }
  end

  def min_step
    @next_steps.keys.min
  end

  def add_to_next_steps(step)
    if step.update_if_better_than(@shortest_paths, @next_steps)
      @next_steps[step.distance] ||= []
      @next_steps[step.distance] << step
    end
  end

  def approaches_to(step)
    @shortest_paths[step]
  end

  memoize def points
    @map
      .each_with_index
      .flat_map do |row, y|
        row.each_with_index.map { |cell, x| [[x, y], cell] }
      end
      .to_h
  end

  def setup
    @shortest_paths = points.keys.map { |pt| [pt, Approaches.new] }.to_h
    @next_steps = { 0 => [Step.new([0, 0], 0, nil, 0)] }
  end
end

class Approaches
  def initialize
    @best = {
      nil => Float::INFINITY,
      [[0, 1], 1] => Float::INFINITY,
      [[0, 1], 2] => Float::INFINITY,
      [[0, 1], 3] => Float::INFINITY,
      [[1, 0], 1] => Float::INFINITY,
      [[1, 0], 2] => Float::INFINITY,
      [[1, 0], 3] => Float::INFINITY,
      [[0, -1], 1] => Float::INFINITY,
      [[0, -1], 2] => Float::INFINITY,
      [[0, -1], 3] => Float::INFINITY,
      [[-1, 0], 1] => Float::INFINITY,
      [[-1, 0], 2] => Float::INFINITY,
      [[-1, 0], 3] => Float::INFINITY
    }
  end

  def update_if_better_than(distance, direction, impetus, next_steps)
    # This is kinda nasty but I don't want to think about it
    updated = false
    impetus
      .upto(3)
      .each do |compare_impetus|
        next unless distance < @best[[direction, compare_impetus]]

        @best[[direction, compare_impetus]] = distance
        updated = true
      end

    updated
  end

  def best
    @best.values.min
  end
end

class Step
  attr_reader :distance
  def initialize(point, distance, direction, impetus)
    @point = point
    @distance = distance
    @direction = direction
    @impetus = impetus
  end

  def possible_steps(map, bounds)
    [[0, 1], [1, 0], [0, -1], [-1, 0]].map do |direction|
        move_in(direction, map)
      end
      .compact
      .filter { |step| step.impetus_allowed? }
      .filter { |step, _| step.in_bounds?(bounds) }
  end

  def move_in(direction, map)
    dx, dy = direction
    x, y = @point

    return nil unless map[new_point = [x + dx, y + dy]]

    Step.new(
      new_point,
      distance_to(new_point, map),
      direction,
      impetus_on(direction)
    )
  end

  def update_if_better_than(shortest_paths, next_steps)
    shortest_paths[@point].update_if_better_than(
      @distance,
      @direction,
      @impetus,
      next_steps
    )
  end

  def impetus_allowed?
    @impetus <= 3
  end

  def in_bounds?(bounds)
    bounds.in_bounds?(@point)
  end

  def distance_to(step, map)
    x, y = step
    @distance + map[[x, y]]
  end

  def impetus_on(direction)
    direction == @direction ? @impetus + 1 : 1
  end
end

class Bounds
  def initialize(map)
    @xmax = map.first.size
    @ymax = map.size
  end

  def in_bounds?(point)
    x, y = point

    x >= 0 && x <= @xmax && y >= 0 && y <= @ymax
  end
end
