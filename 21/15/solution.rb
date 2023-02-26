$debug = false

def solve =
  RiskMap
    .parse(read_input)
    .then { |it| [it.fastest_path, it.full_map.fastest_path] }

class RiskMap
  attr_reader :risk_levels
  def initialize(risk_levels)
    @risk_levels = risk_levels
  end

  attr_reader :tracers
  def fastest_path
    paths[[0, 0]] = 0
    @tracers = [[0, 0]]
    follow_tracer until tracers.empty?

    paths[max_x_y]
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

  def follow_tracer
    debug_trace

    x, y = tracers.shift

    neighbors([x, y]).each do |nx, ny|
      dist_to_follow = paths[[x, y]] + risk_levels[[nx, ny]]

      unless paths[[nx, ny]]
        paths[[nx, ny]] = dist_to_follow
        tracers << [nx, ny]
        next
      end

      next if paths[[nx, ny]] <= dist_to_follow

      paths[[nx, ny]] = dist_to_follow
      tracers << [nx, ny]
    end
  end

  def debug_trace
    return unless $debug
    @i ||= 0
    if (@i += 1) % 1000 == 0
      debug(
        tracers: tracers.size,
        paths: paths.size,
        i: @i,
        path: paths[max_x_y]
      )
    end
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
