$_debug = true

class Blizzard
  shape :blizzards, :elf, :bounds

  def self.parse(text)
    new(blizzards: blizzards(text), elf: [1, 0], bounds: bounds(text))
  end

  def self.blizzards(text)
    text
      .split("\n")
      .each_with_index
      .flat_map { |line, y| blizzards_in_line(line, y) }
      .to_h
  end

  def self.blizzards_in_line(line, y)
    line
      .chars
      .each_with_index
      .map { |char, x| [[x, y], [char]] if %w[> v < ^].include?(char) }
      .compact
  end

  def finished?
    elf == [bounds.first - 2, bounds.last - 1]
  end

  def self.bounds(text)
    [text.lines.first.chars.count - 1, text.lines.count]
  end

  def fewest_moves
    shortest_path.size
  end

  def shortest_path
    Searcher.new(self).shortest_path
  end

  def possible_moves
    ElfMover.new(blizzard_game: self).possible_moves
  end

  def update
    Blizzard.new(blizzards: next_blizzards, elf:, bounds:)
  end

  def next_blizzards
    blizzard_updater.update
  end

  def blizzard_updater
    BlizzardUpdater.new(blizzards:, bounds:)
  end

  def out_of_bounds?(point)
    blizzard_updater.out_of_bounds?(point)
  end

  def with_elf(elf)
    Blizzard.new(blizzards: blizzards, elf: elf, bounds: bounds)
  end

  def debug
    elf = self.elf == [1, 0] ? "E" : "."
    puts "##{elf}" + "#" * (bounds.first - 2)
    (1.upto(bounds.last - 2)).each do |y|
      print "#"
      (1.upto(bounds.first - 2)).each { |x| print_square([x, y]) }
      puts "#"
    end
    puts ("#" * (bounds.first - 2)) + ".#"
  end

  def print_square(pt)
    return print "." unless blizzards[pt] || elf == pt
    return print "E" if elf == pt
    raise "Impossible blizzard" unless blizzards[pt]

    print_blizzards(pt)
  end

  def print_blizzards(pt)
    print(
      if blizzards[pt].size == 1
        blizzards[pt].first
      else
        blizzards[pt].size
      end
    )
  end
end

class BlizzardUpdater
  shape :blizzards, :bounds

  def update
    blizzards
      .flat_map { |pt, blzs| blzs.map { |blz| [next_blizzard(pt, blz), blz] } }
      .group_by(&:first)
      .transform_values { |pts| pts.map(&:last) }
  end

  def next_blizzard((x, y), blz)
    new_point =
      case blz
      when "<"
        [x - 1, y]
      when ">"
        [x + 1, y]
      when "^"
        [x, y - 1]
      when "v"
        [x, y + 1]
      end

    out_of_bounds?(new_point) ? wrap_point(new_point) : new_point
  end

  def out_of_bounds?((x, y))
    return false if [x, y] == [bounds.first - 2, bounds.last - 1]

    x < 1 || y < 1 || x >= bounds.first - 1 || y >= bounds.last - 1
  end

  def wrap_point((x, y))
    [wrap(x, bounds.first), wrap(y, bounds.last)]
  end

  def wrap(value, bound)
    return bound - 2 if value < 1
    return 1 if value >= bound - 1

    value
  end
end

class ElfMover
  shape :blizzard_game

  def possible_moves
    moves_from(blizzard_game.update, blizzard_game.elf)
  end

  def moves_from(future_board, current_elf)
    all_moves(current_elf)
      .filter { |point| in_bounds?(point) }
      .filter { |(x, y)| future_board.blizzards[[x, y]].nil? }
      .map { |move| future_board.with_elf(move) }
  end

  def all_moves((x, y))
    [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1], [x, y]]
  end

  def in_bounds?(point)
    !blizzard_game.out_of_bounds?(point)
  end
end

class StateTracker
  def initialize(state, history = [])
    @state = state
    @history = history
  end

  def possible_moves
    @state.possible_moves.map do |move|
      StateTracker.new(move, @history + [@state])
    end
  end

  def finished?
    @state.finished?
  end

  def size
    @history.size
  end

  def history
    @history
  end

  def uniq
    [@state.blizzards, @state.elf]
  end
end

class Searcher
  def initialize(blizzard_game_state)
    @states = [StateTracker.new(blizzard_game_state)]
  end

  def shortest_path
    until @states.any?(&:finished?)
      @states = @states.flat_map(&:possible_moves).reject { |s| seen?(s.uniq) }
      _debug("Searching...", steps: @states.first&.size, states: @states.size)
      @states.first.history.last.debug
    end

    @states.find { |s| s.finished? }.history
  end

  def seen?(state)
    @seen ||= Set.new
    return true if @seen.include?(state)

    @seen << state
    false
  end
end
