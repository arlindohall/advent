
class Path
  attr_reader :points
  def intialize(points, done = false)
    @points = points
    @done = done
  end

  def visit(point)
    Path.new(@points + [point])
  end

  def contains(point)
    @points.include?(point)
  end

  def open_spaces_in(grid)
    grid.open_spaces(@points.last)
      .map { |pt| visit(pt) }
  end

  def done?
    @done
  end
end

class Move
  def initialize(pt1, pt2, state)
    @pt1, @pt2, @state = pt1, pt2, state
  end

  def reassign(grid)
    raise "Unable to reassign to grid from state #{@state}" unless @state == :move
    @grid[@pt1], @grid[@pt2] = @grid[@pt2], @grid[@pt1]
  end

  def should_attack?
    state == :attack || state == :move_and_attack
  end

  def should_move?
    state == :move_and_attack
  end

  def no_moves?
    state == :no_moves
  end
end

class Point
  def is_player? ; false ; end
  def is_open? ; is_a?(Point) ; end
end

class Obstacle < Point
end

class Elf < Point
  def initialize(id)
    @id = id
  end

  def is_player? ; true ; end
  def type ; :elf ; end
end

class Goblin < Point
  def initialize(id)
    @id = id
  end

  def is_player? ; true ; end
  def type ; :goblin ; end
end

class GoblinFight
  attr_reader :grid, :players

  def initialize(grid, players)
    @grid = grid
    @players = players
  end

  def round
    ordered.each { |player|
      mv = move(player)
      return if mv.no_moves?
      swap(mv) if mv.should_move?
      attack(player) if mv.should_attack?
    }
  end

  def move(player)
    adjacent_enemies = enemies(@players[player])
    return Move.new(@players[player], ordered(adjacent_enemies).first, :attack) if adjacent_enemies.any?

    targets = @players.filter { |pl, _loc| pl.type != player.type }
      .flat_map { |_pl, loc| open_spaces(loc) }
    paths = open_spaces(@players[player]).map { |loc| Path.new([loc], false) }

    until paths.any?(&:done?)
      steps = paths.flat_map { |pth| pth.open_spaces_in(@grid, player.type) }
        .filter { |open_step| paths.none? { |pth| pth.contains(open_step.points.last) } }
    end
  end

  def open_spaces(player)
    @xmax ||= @grid.keys.map(&:first).max
    @ymax ||= @grid.keys.map(&:last).max

    [
      [player.first - 1, player.last],
      [player.first + 1, player.last],
      [player.first, player.last - 1],
      [player.first, player.last + 1]
    ].filter { |x,y| x >= 0 && y >= 0 && y <= @ymax && x <= @xmax }
      .filter { |x,y| @grid[[x,y]].is_open? }
  end

  def distance(pt1, pt2)
    pt1.zip(pt2).map { |x,y| x-y }.map(&:abs).sum
  end

  def ordered(points = nil)
    ordered = points.nil? ?
      @players.values :
      @players.filter { |player, _loc| points.include?(player) }
        .map(&:last)

    ordered.sort_by { |loc| loc.first }
      .sort_by { |loc| loc.last }
  end

  def self.of(text)
    grid = self.grid(text)
    new(grid, players(grid))
  end

  def self.players(grid)
    grid.filter { |_loc, obj| obj.is_player? }
      .map { |k, v| [v, k] }
      .to_h
  end

  def self.grid(text)
    grid = {}
    @id = 0
    text.split("\n").each_with_index { |row, y|
      row.chars.each_with_index { |char, x|
        case char
        when '#'
          grid[[x, y]] = Obstacle.new
        when '.'
          grid[[x, y]] = Point.new
        when 'E'
          grid[[x, y]] = Elf.new(@id += 1)
        when 'G'
          grid[[x, y]] = Goblin.new(@id += 1)
        end
      }
    }

    grid
  end
end

@example1 = <<-map
#######
#E..G.#
#...#.#
#.G.#G#
#######
map