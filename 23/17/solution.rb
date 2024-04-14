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
    @text.split("\n").map { |row| row.chars }
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
  end

  def follow_one_step
    if @next_steps[min_step].empty?
      @next_steps.delete(min_step)
      return
    end

    step = @next_steps[min_step].shift

    step.possible_steps(@map, @bounds).each { |step| add_to_next_steps(step) }
  end

  def add_to_next_steps(step)
    raise "Check if it's better than current at that impetus or greater"
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
end

class Step
  def initialize(point, distance, direction, impetus)
    @point = point
    @distance = distance
    @direction = direction
    @impetus = impetus
  end

  def possible_steps(map, bounds)
    directions
      .map { |direction| move_in(direction) }
      .filter { |step| bounds.in_bounds?(step) }
      .map do |step|
        step.new(step, distance_to(step), direction, impetus_on(step))
      end
  end

  def distance_to(step)
    raise "Distance going to step"
  end

  def impetus_on(step)
    raise "Impetus goes up if same direction"
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
