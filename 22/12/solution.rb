$_debug = false

class Terrain
  shape :map, :start, :goal

  def fewest_steps_from_start
    fewest_steps(start)
  end

  def fewest_steps_from_a
    # Could probably reverse the search but this is fast enough
    map
      .filter { |_k, v| v == "a" }
      .map(&:first)
      .map { |pos| fewest_steps(pos) }
      .compact
      .min
  end

  attr_reader :positions, :distances
  def fewest_steps(start)
    @positions = [start]
    @distances = { start => 0 }

    travel_one_step until positions.empty?

    debug_map
    distances[goal]
  end

  def travel_one_step
    _debug("starting one step of travel", positions: positions)
    @positions = positions.flat_map { |pos| visit_neighbors(pos) }
  end

  def visit_neighbors(position)
    _debug("visiting neighbors", position:)
    neighbors(position)
      .tap { |nbs| _debug("neighbors", nbs: nbs) }
      .reject { |nb| distances.key?(nb) }
      .select { |nb| can_travel(position, nb) }
      .each { |nb| distances[nb] = distances[position] + 1 }
  end

  def can_travel(start, finish)
    _debug(
      "checking for travel from",
      start:,
      finish:,
      start_ch: map[start],
      finish_ch: map[finish]
    )

    if map[start] == "S"
      true
    elsif map[finish] == "E"
      "z".ord - map[start].ord <= 1
    else
      map[finish].ord - map[start].ord <= 1
    end
  end

  def neighbors(position)
    x, y = position
    [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]].select { |nb| map[nb] }
  end

  def debug_map
    return unless $_debug
    map
      .keys
      .map(&:second)
      .max
      .times do |y|
        map
          .keys
          .map(&:first)
          .max
          .times do |x|
            print map[[x, y]]
            print "/"
            print distances[[x, y]].to_s.ljust(3)
          end
        puts
      end
  end

  def self.parse(text)
    start, goal = nil, nil
    map =
      text
        .split
        .each_with_index
        .flat_map do |row, y|
          row.chars.each_with_index.map do |char, x|
            start = [x, y] if char == "S"
            goal = [x, y] if char == "E"
            [[x, y], char]
          end
        end
        .to_h
    new(map:, start:, goal:)
  end
end
