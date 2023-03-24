$_debug = false

def solve =
  RiskMap
    .parse(read_input)
    .then { |it| [it.fastest_path, it.full_map.fastest_path] }

class RiskMap
  attr_reader :risk_levels
  def initialize(risk_levels)
    @risk_levels = risk_levels
  end

  attr_reader :unvisited, :distances, :closeness
  def fastest_path
    @unvisited = risk_levels.keys.map.to_set
    @distances = risk_levels.keys.map { |key| [key, Float::INFINITY] }.to_h

    # Dijkstras, sped up by tracking nodes by distances
    @closeness = { 0 => [[0, 0]] }
    distances[[0, 0]] = 0

    visit(closest) until distances[max_x_y] != Float::INFINITY

    distances[max_x_y]
  end

  def closest
    closeness[closeness.keys.min].filter { |node| unvisited.include?(node) }
  end

  def visit(nodes)
    @i ||= 0
    if (@i += 1) % 100 == 0
      _debug(
        closest: closeness.keys.min,
        closenesses: closeness.size,
        unvisited: unvisited.size
      )
    end

    closeness.delete(closeness.keys.min)
    nodes.each do |node|
      unvisited.delete(node)
      neighbors(node)
        .filter { |nb| unvisited.include?(nb) }
        .each do |neighbor|
          next if distances[node] + risk_levels[neighbor] >= distances[neighbor]
          distances[neighbor] = distances[node] + risk_levels[neighbor]

          closeness[distances[neighbor]] ||= []
          closeness[distances[neighbor]] << neighbor
        end
    end
  end

  def full_map
    RiskMap.new(enlarge_map)
  end

  def enlarge_map
    maxx, maxy = max_x_y
    xsize, ysize = maxx + 1, maxy + 1
    0
      .upto(ysize * 5 - 1)
      .flat_map do |y|
        0
          .upto(xsize * 5 - 1)
          .map do |x|
            tile_x = x / xsize
            tile_y = y / ysize

            base_risk = risk_levels[[x % xsize, y % ysize]]
            full_risk = base_risk + tile_x + tile_y
            mod_risk = (full_risk - 1) % 9 + 1

            [[x, y], mod_risk]
          end
      end
      .to_h
  end

  def neighbors(coord)
    x, y = coord
    [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]].filter do |coord|
      risk_levels[coord]
    end
  end

  def max_x_y
    @max_x_y ||= [
      risk_levels.keys.map(&:first).max,
      risk_levels.keys.map(&:second).max
    ]
  end

  def paths
    @paths ||= {}
  end

  def self.parse(text)
    new(
      text
        .split
        .each_with_index
        .flat_map do |row, y|
          row.chars.each_with_index.map { |cell, x| [[x, y], cell.to_i] }
        end
        .to_h
    )
  end
end
