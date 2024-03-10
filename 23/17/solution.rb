class CrucibleMap
  def initialize(text)
    @text = text
  end

  def optimal_heat_loss
    optimal_path.heat_loss
  end

  def optimal_path
    @paths = { 0 => [Path.start] }

    one_iteration_dijkstra until @paths.empty?

    final_spot
  end

  def one_iteration_dijkstra
    _debug("one iteration", @paths.values.map(&:size))
    reachable_from_next.each do |path|
      next unless optimal?(path)
      next if path.four_in_a_row?
      next if worse_than_answer?(path)

      @paths[path.heat_loss] ||= []
      @paths[path.heat_loss] << path
      self.best_path = path
    end
  end

  def optimal?(path)
    return true unless best_path(path)

    best_path(path).heat_loss > path.heat_loss
  end

  def reachable_from_next
    key = @paths.keys.min
    @paths.delete(key).flat_map { |path| path.neighbors_within(heat_map) }
  end

  def heat_map
    @heat_map ||= @text.split("\n").map { |line| line.chars.map(&:to_i) }
  end

  def path_tracker
    @path_tracker ||= PathTracker.new
  end

  def best_path(path)
    path_tracker.best_path(path)
  end

  def best_path=(path)
    path_tracker.best_path = path
  end

  def final_spot
    path_tracker.best_at_square(heat_map.size - 1, heat_map.first.size - 1)
  end

  def worse_than_answer?(path)
    return false unless final_spot

    path.heat_loss > final_spot.heat_loss
  end
end

class PathTracker
  def initialize
    @best_paths = {}
  end

  def best_path(path)
    paths_like(path).filter { |other| }
  end

  def best_path=(path)
  end

  def best_at_square(x, y)
  end

  def paths_at_point(point)
    @best_paths[point] ||= []
    @best_paths[point]
  end
end

class Path
  def self.start
    new([0, 0], [], 0)
  end

  attr_reader :location, :heat_loss
  def initialize(location, history, heat_loss)
    @location = location
    @history = history
    @heat_loss = heat_loss
  end

  def neighbors_within(domain)
    neighbors
      .reject { |x, y| x < 0 || y < 0 }
      .filter { |x, y| domain[y] && domain[y][x] }
      .map { |point| move_to(point, domain) }
  end

  def move_to(point, domain)
    Path.new(
      point,
      @history + [point],
      @heat_loss + heat_loss_for(point, domain)
    )
  end

  def heat_loss_for(point, domain)
    x, y = point
    domain[y][x]
  end

  def neighbors
    x, y = location
    [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]]
  end

  def four_in_a_row?
    return false unless @history.size > 4

    last_four_derivatives.uniq.size == 1
  end

  def last_four_derivatives
    @history
      .last(4)
      .zip(@history.last(5).take(4))
      .map { |(x1, y1), (x2, y2)| [(y1 - y2), (x1 - x2)] }
  end

  def direction
    last_four_derivatives.last
  end

  def speed
    last_four_derivatives.reverse.take_while { |v| v == lfd.first }.size
  end
end
