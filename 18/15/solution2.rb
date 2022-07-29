
LARGE_NUMBER = 100_000_000
def reading_order(point)
  x, y = point
  # Always sort by y first, then x
  LARGE_NUMBER * y + x
end
Player = Struct.new(:hp, :type)

class Player
  DEFAULT_HP = 200

  @@elf_damage = 3
  def self.set_elf_damage(damage)
    @@elf_damage = damage
  end

  def take_damage
    case self.type
    when :elf
      self.hp -= 3
    when :goblin
      self.hp -= @@elf_damage
    else
      raise "Unknown player type: #{type}"
    end
  end

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

class OpenSpace
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

class Path
  def initialize(route)
    @route = route
  end

  def then_visit(point)
    self.class.new(@route + [point])
  end

  def step
    # The terminal is always the starting point, or no move
    # so the step will be the second entry
    @route[1]
  end

  def starting_point
    @route.first
  end

  def terminal
    @route.last
  end

  def distance
    @route.size
  end

  def to_s
    @route.count.to_s
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

    @round * hp_left
  end

  def part2
    @elf_count = count_elves
    @elf_damage = 4

    until elves_win?
      Player.set_elf_damage(@elf_damage)
      @round, @hp_left = simulate_whole_battle
      @elf_damage += 1
    end

    @round * @hp_left
  end

  def elves_win?
    @round
  end

  def simulate_whole_battle
    puts "Simulating with elf damage: #{@elf_damage}"
    map = deep_clone

    until map.done?
      map.round
      if map.count_elves < @elf_count
        puts map.inspect
        return [false, 0]
      end
    end

    puts map.inspect
    [map.rounds, map.hp_left]
  end

  def hp_left
    players_themselves.map(&:hp).sum
  end

  def deep_clone
    Map.new(
      @grid.map { |row|
        row.map { |cell|
          case cell
          when Player
            cell.dup
          else
            cell
          end
        }
      }
    )
  end

  def count_elves
    sort_players.filter { |x,y| @grid[y][x].type == :elf }.count
  end

  def done?
    players_themselves.map(&:type).uniq.length == 1
  end

  def round
    @round ||= 0

    sort_players.dup.each { |player|
      return self if done?
      turn(player)
    }

    @round += 1
    self # for chaining
  end

  def turn(player)
    return unless has_not_died(player)

    move = step(player)
    move.swap(@grid, @players) if move.should_move?

    attack = attack(move.attack_point)
    attack.drain(@grid, @players) if attack.should_attack?
  end

  def has_not_died(player)
    x, y = player
    @grid[y][x].player?
  end

  def attack(player_location)
    Attacker.new(@grid, sort_players, player_location).find_attack
  end

  def step(player_location)
    Mover.new(@grid, sort_players, player_location).find_best_move
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
            OpenSpace.new
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
    @grid = grid
    @players = players
    @starting_point = starting_point
  end

  def targets
    x,y = @starting_point
    type = @grid[y][x].type

    @players.filter { |x,y| @grid[y][x].type != type }
  end

  def enemy
    return @enemy if @enemy

    targets = attackable_neighbors.group_by { |x,y| @grid[y][x].hp }
    @enemy = targets[targets.keys.min]&.min_by { |point| reading_order(point) }
  end

  def attackable_neighbors
    x, y = @starting_point
    raise "Tried to find enemies of non-player #{@starting_point}: #{@grid[y][x]}" unless @grid[y][x].player?

    neighbors(@starting_point).filter { |nx,ny|
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

class Attacker < Searcher
  def initialize(grid, players, starting_point)
    # Do not need to clone grid because we don't mutate it
    super(grid, players, starting_point)
  end

  def find_attack
    Attack.new(@starting_point, enemy)
  end
end

class Mover < Searcher
  def initialize(grid, players, starting_point)
    super(grid.map(&:dup), players, starting_point)
  end

  # Return unfound if no move available, or immediately when path
  # found, but sort by reading order
  def find_best_move
    return Move.no_moves(@starting_point) if Attacker.new(@grid, @players, @starting_point).find_attack.should_attack?

    @moves = [Path.new([@starting_point])]

    until @moves.empty?
      update_next_moves
      set_points_to_path
      return found_move if found_move
    end

    return found_move if found_move

    Move.no_moves(@starting_point)
  end

  def found_move
    mv = shortest_finishing_move
    return nil unless mv

    Move.move(@starting_point, mv)
  end

  def shortest_finishing_move
    shortest_paths.filter { |path| path.step } # already know it's at least one step
      .sort_by { |path| reading_order(path.step) } # sort by first step first so it's sorted underneath terminal
      .sort_by { |path| reading_order(path.terminal) } # sort by terminal last so they're at top
      .first
      &.step
  end

  def shortest_paths
    @moves.filter { |path|
      neighbors(path.terminal).any? { |x,y|
        @grid[y][x].player? && @grid[y][x].type != type
      }
    }
  end

  def type
    x, y = @starting_point
    @grid[y][x].type
  end

  def set_points_to_path
    @moves.each { |pth|
      x, y = pth.terminal
      @grid[y][x] = pth
    }
  end

  def update_next_moves
    @moves = @moves.flat_map { |path| possible_visits_from(path) }
      .group_by { |path| path.terminal }
      .values
      .map { |paths_to_point| paths_to_point.min_by { |pth| reading_order(pth.starting_point) } }
  end

  def possible_visits_from(path)
    neighbors(path.terminal)
      .filter { |x,y| @grid[y][x].path? }
      .map { |ngb| path.then_visit(ngb) }
  end
end

class Attack
  def initialize(player, target)
    @player = player
    @target = target
  end

  class << self
    def no_targets(player)
      new(player, nil)
    end

    def attack(player, target)
      new(player, target)
    end
  end

  def drain(grid, players)
    x, y = @target
    grid[y][x].take_damage

    return if grid[y][x].hp > 0

    grid[y][x] = OpenSpace.new
  end

  def to_s
    " (attack #{@target})"
  end

  def should_attack?
    !@target.nil?
  end
end

class Move
  def initialize(player, destination)
    @player = player 
    @destination = destination
  end

  class << self
    def no_moves(starting_point)
      new(starting_point, nil)
    end

    def move(player, destination)
      new(player, destination)
    end
  end

  def swap(grid, players)
    px, py = @player
    dx, dy = @destination

    players.delete(@player)
    players << @destination

    grid[dy][dx], grid[py][px] = grid[py][px], grid[dy][dx]
  end

  def attack_point
    @destination ? @destination : @player
  end

  def to_s
    @destination ? "#{@player.to_s.ljust(10)} -> #{@destination}" : "#{@player.to_s.ljust(10)} -> no move"
  end

  def should_move?
    !@destination.nil?
  end
end

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
#E..EG#
#.#G.E#
#E.##E#
#G..#.#
#..E#.#
#######
map

@example3 = <<map.strip
#######
#E.G#.#
#.#G..#
#G.#.G#
#G..#.#
#...E.#
#######
map

@example4 = <<map.strip
#######
#.E...#
#.#..G#
#.###.#
#E#G#G#
#...#G#
#######
map

@example5 = <<map.strip
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

def all_examples
  results = 1.upto(5).map { |i| self.instance_variable_get("@example#{i}") }
    .map { |g| Map.parse(g) }
    .map(&:part2)
  
  expected = [
    4988,
    31284,
    3478,
    6474,
    1140,
  ]

  raise "Expected all equal #{results.zip(expected)}" unless
    results.zip(expected).all? { |r, e| r == e }
end