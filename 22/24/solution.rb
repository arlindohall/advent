$_debug = false

def solve(input = read_input) =
  [Blizzard.parse(input).fewest_moves, Blizzard.parse(input).fewest_round_trip]

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

  def finished?(elf)
    elf == target
  end

  attr_accessor :target
  def target
    @target || [bounds.first - 2, bounds.last - 1]
  end

  def self.bounds(text)
    [text.lines.first.chars.count - 1, text.lines.count]
  end

  def fewest_moves
    shortest_path.time
  end

  def fewest_round_trip
    shortest_round_trip.time
  end

  def shortest_path
    Searcher.new(self).shortest_path
  end

  def shortest_round_trip
    RoundTripSearcher.new(self).shortest_path
  end

  def initial_state
    State[elf:, time: 0]
  end

  def blizzard_at?(state)
    blizzard_predictor.blizzard_at?(state)
  end

  def out_of_bounds?(pt)
    BlizzardUpdater.new(blizzards:, bounds:).out_of_bounds?(pt)
  end

  def blizzard_predictor
    @_blizzard_predictor ||= BlizzardPredictor.new(blizzards, bounds)
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

class Searcher
  def initialize(blizzard_game, state = nil)
    @blizzard_game = blizzard_game
    @states = [state || blizzard_game.initial_state]
  end

  def shortest_path
    until @states.any? { |s| @blizzard_game.finished?(s.elf) }
      @states =
        @states.flat_map { |s| possible_moves(s) }.reject { |s| seen?(s.uniq) }
      _debug("Searching states", size: @states.size)

      binding.pry if @states.empty?
      raise "No path founds" if @states.empty?
    end

    @states.find { |s| @blizzard_game.finished?(s.elf) }
  end

  def seen?(state)
    @seen ||= Set.new
    return true if @seen.include?(state)

    @seen << state
    false
  end

  def possible_moves(state)
    state.possible_moves(@blizzard_game)
  end
end

class RoundTripSearcher
  def initialize(blizzard_game)
    @blizzard_game = blizzard_game
    @start = blizzard_game.initial_state.elf
    @finish = blizzard_game.target
  end

  def shortest_path
    state = get_there(@blizzard_game.initial_state)
    state = go_back(state)
    state = get_there(state)

    state
  end

  def get_there(state)
    @blizzard_game.target = @finish
    Searcher.new(@blizzard_game, state).shortest_path
  end

  def go_back(state)
    @blizzard_game.target = @start
    Searcher.new(@blizzard_game, state).shortest_path
  end
end

class State
  shape :elf, :time

  def uniq
    [elf, time]
  end

  def possible_moves(blizzard_game)
    all_moves
      .reject { |pt| blizzard_game.out_of_bounds?(pt) }
      .map { |pt| State[elf: pt, time: time + 1] }
      .reject { |st| blizzard_game.blizzard_at?(st) }
  end

  def all_moves
    x, y = elf

    [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1], [x, y]]
  end
end

class BlizzardPredictor
  def initialize(blizzards, bounds)
    @blizzards = blizzards
    @bounds = bounds
  end

  def blizzard_at?(state)
    mod_time = state.time % lcm_of_board_dimensions
    raise "Out of time bounds" unless blizzard_predictions[mod_time]

    !!blizzard_predictions[mod_time][state.elf]
  end

  def blizzard_predictions
    return @predictions if @predictions

    @predictions = {}

    lcm_of_board_dimensions.times do |i|
      @predictions[i] = @blizzards
      update_blizzards
    end
  end

  def lcm_of_board_dimensions
    x, y = @bounds.map { |b| b - 2 }

    x.lcm(y)
  end

  def update_blizzards
    @blizzards = blizzard_updater.update
  end

  def blizzard_updater
    BlizzardUpdater.new(blizzards: @blizzards, bounds: @bounds)
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
    return false if [x, y] == target || [x, y] == start

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

  def target
    [bounds.first - 2, bounds.last - 1]
  end

  def start
    [1, 0]
  end
end
