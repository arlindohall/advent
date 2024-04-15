class CrucibleMap
  def initialize(text)
    @text = text
  end

  memoize def map
    @text.split("\n").map { |line| line.split("").map(&:to_i) }
  end

  def part_1
    seen = Set.new
    queue = PriorityQueue.new { |state| -state.heat_loss } # PQ pops the max key

    [
      LocDirecHeatLoss[LocDirec[[0, 0], [1, 0], 0], 0],
      LocDirecHeatLoss[LocDirec[[0, 0], [0, 1], 0], 0]
    ].each do |state|
      queue << state
      seen << state.loc_direc
    end

    until queue.empty?
      current = queue.pop
      return current.heat_loss if current.loc_direc.location == goal

      [[1, 0], [0, 1], [-1, 0], [0, -1]].reject do |direction|
          backtracking?(current, direction)
        end
        .filter do |direction|
          in_bounds?(current.loc_direc.next_location(direction))
        end
        .filter do |direction|
          distance = current.loc_direc.distance + 1
          distance < 3 || current.loc_direc.direction != direction
        end
        .map do |direction|
          next_location = current.loc_direc.next_location(direction)
          distance = 0
          if current.loc_direc.direction == direction
            distance = current.loc_direc.distance + 1
          end

          LocDirecHeatLoss[
            LocDirec[next_location, direction, distance],
            current.heat_loss + map[next_location.second][next_location.first]
          ]
        end
        .reject { |state| seen.include?(state.loc_direc) }
        .each do |state|
          seen << state.loc_direc
          queue << state
        end
    end

    raise "No path found"
  end

  def part_2
    seen = Set.new
    queue = PriorityQueue.new { |state| -state.heat_loss } # PQ pops the max key

    [
      LocDirecHeatLoss[LocDirec[[0, 0], [1, 0], 0], 0],
      LocDirecHeatLoss[LocDirec[[0, 0], [0, 1], 0], 0]
    ].each do |state|
      queue << state
      seen << state.loc_direc
    end

    until queue.empty?
      current = queue.pop
      if current.loc_direc.location == goal &&
           current.loc_direc.distance >= 4 && current.loc_direc.distance < 10
        return current.heat_loss
      end

      [[1, 0], [0, 1], [-1, 0], [0, -1]].reject do |direction|
          backtracking?(current, direction)
        end
        .filter do |direction|
          in_bounds?(current.loc_direc.next_location(direction))
        end
        .filter do |direction|
          distance = current.loc_direc.distance + 1
          (distance < 4 && current.loc_direc.direction == direction) ||
            (distance >= 10 && current.loc_direc.direction != direction) ||
            (distance >= 4 && distance < 10)
        end
        .map do |direction|
          next_location = current.loc_direc.next_location(direction)
          distance = 0
          if current.loc_direc.direction == direction
            distance = current.loc_direc.distance + 1
          end

          LocDirecHeatLoss[
            LocDirec[next_location, direction, distance],
            current.heat_loss + map[next_location.second][next_location.first]
          ]
        end
        .reject { |state| seen.include?(state.loc_direc) }
        .each do |state|
          seen << state.loc_direc
          queue << state
        end
    end

    raise "No path found"
  end

  def goal
    [map.first.size - 1, map.size - 1]
  end

  def in_bounds?((x, y))
    x >= 0 && x < map.first.size && y >= 0 && y < map.size
  end

  def backtracking?(current, direction)
    direction == [0, 1] && current.loc_direc.direction == [0, -1] ||
      direction == [0, -1] && current.loc_direc.direction == [0, 1] ||
      direction == [1, 0] && current.loc_direc.direction == [-1, 0] ||
      direction == [-1, 0] && current.loc_direc.direction == [1, 0]
  end

  LocDirecHeatLoss = Struct.new(:loc_direc, :heat_loss)
  LocDirec =
    Struct.new(:location, :direction, :distance) do
      def next_location((dx, dy))
        x, y = location
        [dx + x, dy + y]
      end
    end
end
