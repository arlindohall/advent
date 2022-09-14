
Asteroid = Struct.new(:x, :y)

class Grid
  def initialize(asteroids)
    @asteroids = asteroids
  end

  def winning_bet
    asteroid = blasting_order[199]
    asteroid.x * 100 + asteroid.y
  end

  def setup_blaster
    @center = all_detected.max_by { |_k, v| v.size }.first
    @asteroids.delete(@center)
    @angle = Math.atan2(1, 1_000_000)
    @blasted = []
  end

  attr_reader :center, :asteroids, :angle, :blasted
  def blasting_order
    setup_blaster

    until @blasted.size == 200 || @asteroids.empty?
      @blasted << next_blasted
      @angle = next_angle
      @asteroids.delete(@blasted.last)
    end

    @blasted
  end

  def next_blasted
    lines_of_sight(@center)[next_angle]
      .sort_by { |other| distance(@center, other) }
      .first
  end

  def distance(asteroid, other)
    [
      asteroid.x - other.x,
      asteroid.y - other.y,
    ]
      .map(&:abs)
      .sum
  end

  def next_angle
    if @angle <= all_angles.min
      all_angles.max
    else
      all_angles.sort.reverse.filter { |a| a < @angle }.first
    end
  end

  def all_angles
    lines_of_sight(@center).keys
  end

  def most_detected
    all_detected.values.map(&:count).max
  end

  def dump_los
    maxx, maxy = @asteroids.map(&:x).max, @asteroids.map(&:y).max
    puts 0.upto(maxy).map { |y|
      0.upto(maxx).map { |x|
        map_los[Asteroid[x,y]]&.to_s || '.'
      }.join
    }.join("\n")
  end

  def map_los
    @map_los ||= all_detected.transform_values { |list| list.size }
  end

  def all_detected
    @asteroids.map { |asteroid| [asteroid, detected(asteroid)] }
      .to_h
  end

  def detected(asteroid)
    lines_of_sight(asteroid)
      .map { |los, as| as.first }
  end

  def lines_of_sight(asteroid)
    exclude(asteroid)
      .group_by { |other| line_of_sight(asteroid, other) }
  end

  def exclude(asteroid)
    @asteroids.filter { |other| other != asteroid }
  end

  def line_of_sight(asteroid, other)
    dx, dy = asteroid.x - other.x, asteroid.y - other.y

    Math.atan2(dx, dy)
  end

  class << self
    def parse(text)
      asteriods = text.split("\n").each_with_index.flat_map { |line, y|
        line.chars.each_with_index.map { |ch, x|
          Asteroid[x, y] if ch == '#'
        }.compact
      }

      Grid.new(asteriods)
    end
  end
end

def solve
  [
    Grid.parse(@input).most_detected,
    Grid.parse(@input).winning_bet,
  ]
end

def test
  [
    @example1, 8,
    @example2, 33,
    @example3, 35,
    @example4, 41,
    @example5, 210,
  ].each_slice(2) { |example, best|
    raise "part1 should =#{best}" unless Grid.parse(example).most_detected == best
  }

  raise "part2" unless Grid.parse(@example5).winning_bet == 802

  :success
end

@input = <<-asteroids.strip
##.##..#.####...#.#.####
##.###..##.#######..##..
..######.###.#.##.######
.#######.####.##.#.###.#
..#...##.#.....#####..##
#..###.#...#..###.#..#..
###..#.##.####.#..##..##
.##.##....###.#..#....#.
########..#####..#######
##..#..##.#..##.#.#.#..#
##.#.##.######.#####....
###.##...#.##...#.######
###...##.####..##..#####
##.#...#.#.....######.##
.#...####..####.##...##.
#.#########..###..#.####
#.##..###.#.######.#####
##..##.##...####.#...##.
###...###.##.####.#.##..
####.#.....###..#.####.#
##.####..##.#.##..##.#.#
#####..#...####..##..#.#
.##.##.##...###.##...###
..###.########.#.###..#.
asteroids

@example1 = <<-asteroids.strip
.#..#
.....
#####
....#
...##
asteroids

@example2 = <<-asteroids.strip
......#.#.
#..#.#....
..#######.
.#.#.###..
.#..#.....
..#....#.#
#..#....#.
.##.#..###
##...#..#.
.#....####
asteroids

@example3 = <<-asteroids.strip
#.#...#.#.
.###....#.
.#....#...
##.#.#.#.#
....#.#.#.
.##..###.#
..#...##..
..##....##
......#...
.####.###.
asteroids

@example4 = <<-asteroids.strip
.#..#..###
####.###.#
....###.#.
..###.##.#
##.##.#.#.
....###..#
..#.#..#.#
#..#.#.###
.##...##.#
.....#.#..
asteroids

@example5 = <<-asteroids.strip
.#..##.###...#######
##.############..##.
.#.######.########.#
.###.#######.####.#.
#####.##.#.##.###.##
..#####..#.#########
####################
#.####....###.#.#.##
##.#################
#####.##.###..####..
..######..##.#######
####.##.####...##..#
.#####..#.######.###
##...#.##########...
#.##########.#######
.####.#.###.###.#.##
....##.##.###..#####
.#.#.###########.###
#.#.#.#####.####.###
###.##.####.##.#..##
asteroids