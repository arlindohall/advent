
class Cluster
  INITIAL_DIRECTION = :up

  attr_reader :infections, :nodes

  def initialize(nodes, carrier, direction, infections)
    @nodes = nodes
    @carrier = carrier
    @direction = direction
    @infections = infections
  end

  def self.of(text)
    new(
      parse(text),
      [0, 0],
      INITIAL_DIRECTION,
      0,
    )
  end

  def self.parse(text)
    grid = Set.new

    chars = text.split("\n").map(&:chars)

    chars.each_with_index do |row, row_idx|
      row.each_with_index do |ch, col_idx|
        if ch == "#"
          y = (chars.size/2) - row_idx
          x = col_idx - (chars.first.size/2)
          grid << [x, y]
        end
      end
    end

    grid
  end

  def dup
    self.class.new(
      @nodes.dup,
      @carrier.dup,
      @direction,
      @infections,
    )
  end

  def solve
    [dup.steps(10000).infections, dup.evolve.steps(10000000).infections]
  end

  def evolve
    EvolvedCluster.new(
      @nodes.each.map{|n| [n, '#']}.to_h,
      @carrier,
      @direction,
      @infections,
    )
  end

  def show
    4.downto(-4) do |y|
      puts -4.upto(4).map { |x|
        if @carrier == [x, y]
          "[#{char_at(x, y)}]"
        else
          " #{char_at(x, y)} "
        end
      }.join
    end
  end

  def steps(n)
    cluster = self
    n.times{ cluster = cluster.burst;

    @i ||= 0
    p @i if (@i += 1) % 10000 == 0
     }
    cluster
  end

  def char_at(x, y)
    return '#' if @nodes.include?([x, y])

    '.'
  end

  def burst
    # perf
    # self.class.new(
    #   toggle_current,
    #   move,
    #   turn,
    #   updated == '#' ? @infections + 1 : @infections
    # )

    new_direction = turn
    new_carrier = move
    new_infections = updated == '#' ?
      @infections + 1 :
      @infections

    @nodes = toggle_current

    @direction = new_direction
    @carrier = new_carrier
    @infections = new_infections
  
    self
  end

  def turn
    if infected?
      turn_right[@direction]
    else
      turn_left[@direction]
    end
  end

  def toggle_current
    infected? ? clean : infect
  end

  def move
    x, y = 0, 0
    case turn
    when :up
      y = 1
    when :right
      x = 1
    when :left
      x = -1
    when :down
      y = -1
    end

    [
      @carrier.first + x,
      @carrier.last + y,
    ]
  end

  private

  def turn_right
    @@turn_right ||= {
      up: :right,
      right: :down,
      down: :left,
      left: :up,
    }
  end

  def turn_left
    @@turn_left ||= turn_right
      .map { |k, v| [v, k] }
      .to_h
  end

  def updated
    if infected?
      '.'
    else
      '#'
    end
  end

  def clean
    @nodes - Set[@carrier]
  end

  def infect
    @nodes + Set[@carrier]
  end

  def infected?
    @nodes.include?(@carrier)
  end
end

class EvolvedCluster < Cluster
  def char_at(x, y)
    @nodes[[x, y]] || '.'
  end

  def toggle_current
    case @nodes[@carrier]
    when nil, 'W', '#'
      update_current(updated)
    when 'F'
      clean
    end

    @nodes
  end

  def turn
    case @nodes[@carrier]
    when nil
      turn_left[@direction]
    when 'W'
      @direction
    when '#'
      turn_right[@direction]
    when 'F'
      reverse[@direction]
    end
  end

  private

  def updated
    case @nodes[@carrier]
    when nil
      'W'
    when 'W'
      '#'
    when '#'
      'F'
    when 'F'
      '.'
    end
  end

  def clean
    # @nodes.keys
    #   .filter { |k| k != @carrier }
    #   .compact
    #   .map{ |k| [k, @nodes[k]] }
    #   .to_h

    @nodes.delete(@carrier)
  end

  def update_current(new_value)
    # perf
    # cheating pure functional programming here by just
    # modifying the existing hash, but you can remove the '!'
    # it'll just be a lot slower
    # @nodes.merge({@carrier => new_value})

    @nodes[@carrier] = new_value
  end

  def reverse
    @@reverse ||= {
      up: :down,
      right: :left,
      down: :up,
      left: :right,
    }
  end
end

@example = <<-grid.strip
..#
#..
...
grid

@input = <<-grid.strip
.##.#..#...#....###....#.
#.#######.##.##.#.##.##..
.##.#..#.###.#....###..##
......#.#..##.##...#.#.##
.#.##.##.######...##.#..#
###...#..####..######.#..
###....#....#..#####.#.##
..##..#..#.#.#.#....#####
#.#.......##.#....##..#.#
##..#.###.##.####.##...#.
#.####.##.##..##.#.##.##.
###.#..##.##.#.####...#..
######.#...#....#.#...#..
.#.#.###.##.##..#.#....##
#.###..##....###.###..#.#
.#..##.......#..#.##.##.#
..#...####...##.#.##..#.#
..#.##..#..##.###.#####.#
##..##.##....#..###.#.###
.#..######.#.####..#.###.
##...####..##.#.#.#.#.###
#.#....###...##.##..##.#.
..###.#####.####.#.#..#..
..####..#.#....#.###.....
.#......#.#..####.###....
grid