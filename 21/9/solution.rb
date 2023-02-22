def solve =
  LavaTubes
    .parse(read_input)
    .then { |tb| [tb.dup.low_point_risks, tb.dup.three_largest] }

class LavaTubes
  attr_reader :map
  def initialize(map)
    @map = map
  end

  def low_point_risks
    low_points.map { |loc| risk_level(loc) }.sum
  end

  def three_largest
    build_basins.map(&:size).sort.last(3).product
  end

  def basins
    @basins ||= low_points.map { |pt| Set[pt] }
  end

  def build_basins
    basins.map { |bsn| maximize(bsn) }.uniq
  end

  def maximize(bsn)
    @i ||= 0
    basins.each { |other| return other if other > bsn }
    bsn = bsn + non_nine_neighbors(bsn) until bsn >= non_nine_neighbors(bsn)

    bsn
  end

  def non_nine_neighbors(set)
    set
      .flat_map { |pt| neighbors(pt).filter { |pt| map[pt] && map[pt] != 9 } }
      .to_set
  end

  def low_points
    map.filter { |loc, val| neighbor_heights(loc).all? { |nb| nb > val } }.keys
  end

  def risk_level(loc)
    map[loc] + 1
  end

  def neighbor_heights(loc)
    neighbors(loc).map { |loc| map[loc] }.compact
  end

  def neighbors(loc)
    x, y = loc
    [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]]
  end

  def self.parse(text)
    new(
      text
        .split
        .each_with_index
        .flat_map do |row, y|
          row.chars.each_with_index.map { |col, x| [[x, y], col.to_i] }
        end
        .to_h
    )
  end
end
