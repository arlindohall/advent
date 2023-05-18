def solve = Amphipods.new(read_input).then { |it| [it.min, it.oh_shit_min] }

class Amphipods
  shape :text, :map
  attr_reader :text, :cost, :winner, :states

  def min
    @states = [starting_state]
    @winner = State.new(map: {}, cost: Float::INFINITY)
    process_state until states.empty?

    winner.cost
  end

  def oh_shit_min
    augmented_amphipod.min
  end

  def augmented_amphipod
    Amphipods.new(text: augmented_text)
  end

  def augmented_text
    <<~text
      #{text.lines.take(3).join}  #D#C#B#A#
        #D#B#A#C#
      #{text.lines.drop(3).join}
    text
  end

  def process_state
    state = states.shift

    @i ||= 0
    @i += 1
    if @i % 1000 == 0
      _debug(
        "Processing: ",
        processed: @i,
        current_cost: state.cost,
        current_winner: winner.cost,
        states: states.size,
        seen: @seen&.size
      )
      state.debug
    end

    return if seen?(state)
    return if state.cost >= winner.cost

    if state.winning?
      @winner = [state, winner].min_by(&:cost)
      return
    end

    state.moves.each { |mv| states << mv if mv.cost < winner.cost }
  end

  def starting_state
    State.new(map: map, cost: 0)
  end

  def seen?(state)
    @seen ||= {}
    unless @seen.include?(state.map)
      @seen[state.map] = state.cost
      return false
    end
    return true if @seen[state.map] <= state.cost
    @seen[state.map] = state.cost
    false
  end

  def map
    @map ||= build_map
  end

  def target(letter)
    case letter
    when "A"
      3
    when "B"
      5
    when "C"
      7
    when "D"
      9
    end
  end

  def build_map
    map = {}
    text
      .split("\n")
      .each_with_index do |row, y|
        row.chars.each_with_index do |cell, x|
          map[[x, y]] = cell if ".ABCD".include?(cell)
        end
      end
    map
  end
end

class State
  shape :map, :cost

  def winning?
    [3, 5, 7, 9].all? { |x| all_in_column?(x) }
  end

  def all_in_column?(x)
    2.upto(5).all? { |y| right_column?(x, map[[x, y]]) }
  end

  def moves
    map
      .keys
      .flat_map { |coord| moves_from(coord).map { |dest| [coord, dest] } }
      .map { |src, dest| move(src, dest) }
  end

  def move(src, dest)
    State.new(
      map: map.merge(dest => map[src]).merge(src => "."),
      cost: cost + scaled_cost(src, dest)
    )
  end

  def scaled_cost(src, dest)
    cost_for(src, dest) * scale(map[src])
  end

  def scale(amphipod)
    case amphipod
    when "A"
      1
    when "B"
      10
    when "C"
      100
    when "D"
      1000
    end
  end

  def cost_for(src, dest)
    xs, ys = src
    xd, yd = dest

    if yd == 1 || ys == 1
      [xs - xd, ys - yd].map(&:abs).sum
    else
      ys - 1 + yd - 1 + (xs - xd).abs
    end
  end

  def moves_from(coord)
    return [] if map[coord] == "."
    return [] if settled?(coord)

    accessible_from(coord)
      .reject { |dest| from_hallway_to_hallway?(coord, dest) }
      .reject { |dest| outside_room?(dest) }
      .reject { |dest| into_wrong_room?(coord, dest) }
  end

  def accessible_from(coord)
    accessible = Set.new
    visited = Set[]
    queue = [coord]
    until queue.empty?
      point = queue.shift
      visited << point
      neighbors(point)
        .reject { |nb| occupied?(nb) }
        .reject { |nb| visited.include?(nb) }
        .each { |nb| accessible << nb }
        .each { |nb| queue << nb }
    end
    accessible
  end

  def neighbors(coord)
    x, y = coord
    [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]].filter { |nb| map[nb] }
  end

  def occupied?(coord)
    map[coord] != "."
  end

  def settled?(coord)
    x, y = coord

    y.upto(5).all? { |y| right_column?(x, map[[x, y]]) }
  end

  def outside_room?(coord)
    x, y = coord

    y == 1 && [3, 5, 7, 9].include?(x)
  end

  def into_wrong_room?(src, dest)
    amphipod = map[src]
    x, y = dest
    return false if y == 1

    return true unless amphipod && right_column?(x, amphipod)
    (y + 1).upto(5) { |y| return true unless right_column?(x, map[[x, y]]) }

    false
  end

  def right_column?(x, amphipod)
    return true if amphipod.nil?

    case amphipod
    when "A"
      x == 3
    when "B"
      x == 5
    when "C"
      x == 7
    when "D"
      x == 9
    end
  end

  def from_hallway_to_hallway?(src, dest)
    _xs, ys = src
    _xd, yd = dest

    ys == 1 && yd == 1
  end

  def debug
    1.upto(5) do |y|
      1.upto(12) { |x| print map[[x, y]] || " " }
      puts
    end
  end
end
