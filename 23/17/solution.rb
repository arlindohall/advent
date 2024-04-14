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
      if current.loc_direc.location == [map.first.size - 1, map.size - 1]
        return current.heat_loss
      end

      [[1, 0], [0, 1], [-1, 0], [0, -1]].reject do |direction|
          direction == [0, 1] && current.loc_direc.direction == [0, -1] ||
            direction == [0, -1] && current.loc_direc.direction == [0, 1] ||
            direction == [1, 0] && current.loc_direc.direction == [-1, 0] ||
            direction == [-1, 0] && current.loc_direc.direction == [1, 0]
        end
        .filter do |direction|
          dx, dy = direction
          x, y = current.loc_direc.location
          x + dx >= 0 && x + dx < map.first.size && y + dy >= 0 &&
            y + dy < map.size
        end
        .filter do |direction|
          distance = current.loc_direc.distance + 1
          distance < 3 || current.loc_direc.direction != direction
        end
        .map do |direction|
          dx, dy = direction
          x, y = current.loc_direc.location
          distance =
            (
              if current.loc_direc.direction == direction
                current.loc_direc.distance + 1
              else
                0
              end
            )
          LocDirecHeatLoss[
            LocDirec[[dx + x, dy + y], direction, distance],
            current.heat_loss + map[dy + y][dx + x]
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

  LocDirec = Struct.new(:location, :direction, :distance)
  LocDirecHeatLoss = Struct.new(:loc_direc, :heat_loss)
end
