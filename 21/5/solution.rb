def solve =
  HydrothermalVents
    .new(read_input)
    .then { |hv| [hv.overlapping_point_count, hv.all_overlap_count] }

class HydrothermalVents
  attr_reader :text
  def initialize(text)
    @text = text
  end

  def overlapping_point_count
    overlapping_points.count
  end

  def all_overlap_count
    all_overlapping_points.count
  end

  def overlapping_points
    points.filter { |point, paths| paths > 1 }
  end

  def all_overlapping_points
    all_points.filter { |point, paths| paths > 1 }
  end

  def points
    @points ||= flat_lines_points.count_values
  end

  def all_points
    @all_points ||= (flat_lines_points + diagonal_lines_points).count_values
  end

  def flat_lines_points
    horizontal_line_points + vertical_line_points
  end

  def horizontal_line_points
    lines
      .filter { |line| line.start.y == line.end.y }
      .flat_map do |line|
        (line.start.x.to(line.end.x).map { |x| [x, line.start.y] })
      end
  end

  def vertical_line_points
    lines
      .filter { |line| line.start.x == line.end.x }
      .flat_map do |line|
        (line.start.y.to(line.end.y).map { |y| [line.start.x, y] })
      end
  end

  def diagonal_lines_points
    lines
      .filter do |line|
        line.start.x != line.end.x && line.start.y != line.end.y
      end
      .flat_map do |line|
        line.start.x.to(line.end.x).zip(line.start.y.to(line.end.y))
      end
  end

  def lines
    @lines ||= text.split("\n").map { |line| Line.new(line) }
  end

  class Line
    Point = Struct.new(:x, :y)

    attr_reader :text
    def initialize(text)
      @text = text
    end

    def start
      @start ||= Point.new(*text.split(" -> ").first.split(",").map(&:to_i))
    end

    def end
      @end ||= Point.new(*text.split(" -> ").second.split(",").map(&:to_i))
    end
  end
end
