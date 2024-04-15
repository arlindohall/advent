class CrucibleMap
  def initialize(text)
    @text = text
  end

  memoize def map
    @text.split("\n").map { |line| line.split("").map(&:to_i) }
  end

  def part_1 = dijkstra(Small)
  def part_2 = dijkstra(Large)
  def dijkstra(crucible = Small)
    seen = Set.new
    queue = PriorityQueue.new { |state| -state.heat_loss } # PQ pops the max key

    [[1, 0], [0, 1]].each do |dir|
      state = LocDirecHeatLoss[LocDirec[[0, 0], dir, 0], 0]
      queue << state
      seen << state.loc_direc
    end

    until queue.empty?
      current = queue.pop
      return current.heat_loss if crucible.win?(current, goal)

      [[1, 0], [0, 1], [-1, 0], [0, -1]].reject do |direction|
          backtracking?(current, direction)
        end
        .filter do |direction|
          in_bounds?(current.loc_direc.next_location(direction))
        end
        .filter { |direction| crucible.valid_turn?(current, direction) }
        .map { |direction| current.follow(direction, map) }
        .reject { |state| seen.include?(state.loc_direc) }
        .each do |state|
          seen << state.loc_direc
          queue << state
        end
    end

    raise "No path found"
  end

  def goal = [map.first.size - 1, map.size - 1]
  def in_bounds?((x, y))
    x >= 0 && x < map.first.size && y >= 0 && y < map.size
  end

  def backtracking?(current, (dx, dy))
    cx, cy = current.loc_direc.direction
    dx == -cx && dy == -cy
  end

  LocDirecHeatLoss =
    Struct.new(:loc_direc, :heat_loss) do
      def follow(direction, map)
        next_location = loc_direc.next_location(direction)
        distance = 0
        distance = loc_direc.distance + 1 if loc_direc.direction == direction

        LocDirecHeatLoss[
          LocDirec[next_location, direction, distance],
          heat_loss + map[next_location.second][next_location.first]
        ]
      end
    end

  LocDirec =
    Struct.new(:location, :direction, :distance) do
      def next_location((dx, dy))
        x, y = location
        [dx + x, dy + y]
      end
    end

  class Small
    def self.win?(current, goal)
      current.loc_direc.location == goal
    end

    def self.valid_turn?(current, direction)
      distance = current.loc_direc.distance + 1
      distance < 3 || current.loc_direc.direction != direction
    end
  end

  class Large
    def self.win?(current, goal)
      current.loc_direc.location == goal && current.loc_direc.distance >= 4 &&
        current.loc_direc.distance < 10
    end

    def self.valid_turn?(current, direction)
      distance = current.loc_direc.distance + 1
      (distance < 4 && current.loc_direc.direction == direction) ||
        (distance >= 10 && current.loc_direc.direction != direction) ||
        (distance >= 4 && distance < 10)
    end
  end
end
