
Player = Struct.new(:hp, :type)

class Player
  DEFAULT_HP = 200

  def to_s
    type == :elf ? 'E' : 'G'
  end

  def visit?
    false
  end

  def player?
    true
  end

  def path?
    false
  end

  class << self
    def elf
      new(DEFAULT_HP, :elf)
    end

    def goblin
      new(DEFAULT_HP, :goblin)
    end
  end
end

class Path
  def to_s
    '.'
  end

  def visit?
    false
  end

  def player?
    false
  end

  def path?
    true
  end
end

class Obstruction
  def to_s
    '#'
  end

  def visit?
    false
  end

  def player?
    false
  end

  def path?
    false
  end
end

class Visit
  attr_reader :distance
  def initialize(distance)
    @distance = distance
  end

  def to_s
    @distance.to_s
  end

  def visit?
    true
  end

  def player?
    false
  end

  def path?
    false
  end
end

class Map
  def initialize(grid)
    @grid = grid
    sort_players
  end

  def players_themselves
    sort_players.map { |x,y| @grid[y][x] }
  end

  def sort_players
    # Initialize from grid, afterward keep track
    @players = @grid.each_with_index.flat_map { |row, y|
        row.each_with_index.map { |cell, x|
          [x,y] if cell.player?
        }.compact
      }
  end

  def rounds
    @round
  end

  def part1
    until done?
      round
    end

    puts self
    p [@round, players_themselves.map(&:hp).sum, players_themselves.map(&:hp)]
    @round * players_themselves.map(&:hp).sum
  end

  def done?
    players_themselves.map(&:type).uniq.length == 1
  end

  def round
    @round ||= 0

    # puts self
    sort_players.dup.each { |player|
      if has_not_died(player)
        move = step(player)
        # p [@round, player, move]
        move.swap(@grid, @players) if move.should_move?
        move.attack(@grid, @players) if move.should_attack?
      end
    }

    return self if done?

    @round += 1
    p [@round, players_themselves.map(&:hp).sum, players_themselves.map(&:hp)]
    # p [@round, sort_players.length, players_themselves.map(&:hp).sum, players_themselves.map(&:hp)]
    self # for chaining
  end

  def has_not_died(player)
    x, y = player
    @grid[y][x].player?
  end

  def step(player_location)
    Searcher.new(@grid, sort_players, player_location).find_best_move
  end

  def inspect
    "Map:>>>\n----------\n#{self.to_s}\n---------<<<"
  end

  def to_s
    @grid.map { |row| row.map { |ch| ch.to_s.rjust(3) }.join }.join("\n")
  end

  def self.parse(text)
    new(
      text.split("\n").map { |row|
        row.chars.map { |char|
          case char
          when ?#
            Obstruction.new
          when ?.
            Path.new
          when ?G
            Player.goblin
          when ?E
            Player.elf
          else
            raise "Unknown character: #{char}"
          end
        }
      }
    )
  end
end

class Searcher
  def initialize(grid, players, starting_point)
    @grid = grid.map { |row| row.dup }
    @players = players
    @starting_point = starting_point
  end

  def find_best_move
    f = _find_best_move
    # puts "=========="
    # puts Map.new(@grid)
    # puts "=========="
    return f
  end

  # Return unfound if no move available, or immediately when path
  # found, but sort by reading order
  def _find_best_move
    return Move.attack(@starting_point, enemy(@starting_point)) if enemy(@starting_point)

    @distance = 0
    @moves = targets.flat_map { |target| movable_neighbors(target) }

    until @moves.empty?
      return found_move if found_move
      set_points_to_distance
      update_next_moves
    end

    return found_move if found_move

    Move.no_moves(@starting_point)
  end

  def found_move(final_pass = false)
    # Don't need to check if there's all paths because we only want the shortest
    # return nil unless final_pass || neighbors(@starting_point).map { |x,y| @grid[y][x] }.map{ |pt| !pt.path? }.all?
    mv = shortest_finishing_move

    return nil unless mv
    # raise "Expected to have found visit but didn't" unless mv

    x, y = mv
    if @grid[y][x].visit? && @grid[y][x].distance == 0
      raise "Tried to attack from #{@grid[y][x].inspect} but found no enemies" if enemy(mv).nil?
      return Move.attack_and_move(@starting_point, mv, enemy(mv))
    end

    Move.move(@starting_point, mv)
  end

  def shortest_finishing_move
    ngbs = neighbors(@starting_point).filter { |x,y| @grid[y][x].visit? }

    return nil if ngbs.empty?

    dist = ngbs.map { |x,y| @grid[y][x].distance }.min
    ngbs.filter { |x,y| @grid[y][x].distance == dist }.first
  end

  def targets
    x,y = @starting_point
    type = @grid[y][x].type

    @players.filter { |x,y| @grid[y][x].type != type }
  end

  def set_points_to_distance
    @moves.each { |x,y|
      @grid[y][x] = Visit.new(@distance)
    }
  end

  def update_next_moves
    @distance += 1
    # Absolutely critical to `uniq` here because you'll get nearly a million
    # nodes on the search path otherwise
    @moves = @moves.flat_map { |point| movable_neighbors(point) }.uniq
  end

  def enemy(point)
    targets = attackable_neighbors(point).group_by { |x,y| @grid[y][x].hp }
    targets[targets.keys.min]&.min_by { |x,y| y * 10000 + x}
  end

  def attackable_neighbors(point)
    x, y = @starting_point
    raise "Tried to find enemies of non-player #{@starting_point}: #{@grid[y][x]}" unless @grid[y][x].player?

    neighbors(point).filter { |nx,ny|
      @grid[ny][nx].player? && @grid[ny][nx].type != @grid[y][x].type
    }
  end

  def movable_neighbors(point)
    neighbors(point).filter { |x,y| @grid[y][x].path? }
  end

  def neighbor_to(point, neighbor)
    neighbors(point).include?(neighbor)
  end

  def neighbors(point)
    x, y = point
    [
      [x, y - 1],
      [x - 1, y],
      [x + 1, y],
      [x, y + 1],
    ].filter { |x,y| x >= 0 && y >= 0 && x < @grid.first.length && y < @grid.length }
  end
end

class Move
  def initialize(type, player, destination = nil, attack_target = nil)
    @type = type
    @player = player 
    @destination = destination
    @attack_target = attack_target
  end

  class << self
    def no_moves(starting_point)
      new(:no_moves, starting_point)
    end

    def move(player, destination)
      new(:move, player, destination)
    end

    def attack(starting_point, target)
      new(:attack, starting_point, nil, target)
    end

    def attack_and_move(player, destination, target)
      new(:attack_and_move, player, destination, target)
    end
  end

  def swap(grid, players)
    px, py = @player
    dx, dy = @destination

    players.delete(@player)
    players << @destination

    grid[dy][dx], grid[py][px] = grid[py][px], grid[dy][dx]
  end

  def attack(grid, players)
    x, y = @attack_target
    grid[y][x].hp -= 3

    return if grid[y][x].hp > 0

    grid[y][x] = Path.new
  end

  def no_targets?
    @type == :no_targets
  end

  def should_attack?
    [:attack, :attack_and_move].include?(@type)
  end

  def should_move?
    [:move, :attack_and_move].include?(@type)
  end
end

@example_search = <<map.strip
#######
#E..G.#
#...#.#
#.G.#G#
#######
map

@example_step = <<map.strip
#######
#.E...#
#.....#
#...G.#
#######
map

@example_movement = <<map.strip
#########
#G..G..G#
#.......#
#.......#
#G..E..G#
#.......#
#.......#
#G..G..G#
#########
map

@example_attack = [
  [Player.new(9, :goblin),  Path.new, Path.new,               Path.new,               Path.new],
  [Path.new,                Path.new, Player.new(4, :goblin), Path.new,               Path.new],
  [Path.new,                Path.new, Player.new(100, :elf),  Player.new(2, :goblin), Path.new],
  [Path.new,                Path.new, Player.new(2, :goblin), Path.new,               Path.new],
  [Path.new,                Path.new, Path.new,               Player.new(1, :goblin), Path.new],
]

@example1 = <<map.strip
#######
#.G...#
#...EG#
#.#.#G#
#..G#E#
#.....#
#######
map

@example2 = <<map.strip
#######
#G..#E#
#E#E.E#
#G.##.#
#...#E#
#...E.#
#######
map

@example3 = <<map.strip
#######
#E..EG#
#.#G.E#
#E.##E#
#G..#.#
#..E#.#
#######
map

@example4 = <<map.strip
#######
#E.G#.#
#.#G..#
#G.#.G#
#G..#.#
#...E.#
####### 
map

@example5 = <<map.strip
#######
#.E...#
#.#..G#
#.###.#
#E#G#G#
#...#G#
#######
map

@example6 = <<map.strip
#########
#G......#
#.E.#...#
#..##..G#
#...##..#
#...#...#
#.G...G.#
#.....G.#
#########
map

@input = <<map.strip
################################
################.#.#..##########
################.#...G##########
################...#############
######..##########.#..##########
####.G...#########.G...#########
###.........######....##########
##..#.##.....#....#....#########
#G.#GG..................##.#####
##.##..##..G........G.........##
#######......G.G...............#
#######........................#
########.G....#####..E#...E.G..#
#########G...#######...........#
#########...#########.........##
#####.......#########....G...###
###.........#########.....E..###
#...........#########.........##
#..#....G..G#########........###
#..#.........#######.........###
#G.##G......E.#####...E..E..####
##......E...............########
#.....#G.G..............E..#####
#....#####....E........###.#####
#...#########.........####.#####
#.###########......#.#####.#####
#....##########.##...###########
#....#############....##########
##.##############E....##########
##.##############..#############
##....##########################
################################
map

def profile_part_1
  require 'ruby-prof'
  begin
    RubyProf.start
    Map.parse(@input).part1
  ensure
    result = RubyProf.stop
    printer = RubyProf::GraphPrinter.new(result)
    printer.print(STDOUT)
  end
end

def all_examples
  1.upto(6).map { |i| self.instance_variable_get("@example#{i}") }
    .map { |g| Map.parse(g) }
    .map(&:part1)
end

# guess: 182715 <- too low
# Changed number of rounds to increment at start of loop, all examples correct
# 182715 <- same answer, too low
# maybe one more round? a wild guess, would be
# 185526 <- too high
# Multiplication myself, but from the last thing printed, not the end
# 183235 <- too low
#
# 183235 < answer < 185526