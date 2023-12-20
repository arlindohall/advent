$_debug = false

def solve(input = read_input) =
  DishPlatform
    .new(input)
    .then { |dp| [dp.total_load_after_tilt, dp.load_after_billion] }

class DishPlatform
  ONE_BILLION = 1_000_000_000

  def initialize(text)
    @text = text
  end

  def total_load_after_tilt
    platform.tilt.total_load
  end

  def load_after_billion
    state_after_one_billion.total_load
  end

  def state_after_one_billion
    # Force calculate
    period
    state_after(ONE_BILLION)
  end

  def state_after(n)
    return @states_by_number[n] if @states_by_number[n]

    @states_by_number[(n - first_recurrence) % period + first_recurrence]
  end

  memoize def period
    @states_by_number = []
    @numbers_by_state = {}

    @state = platform
    until seen?
      # @state.show
      record
      @state = next_state
    end

    states_seen - first_recurrence
  end

  # First time we saw the most recent state, should only work if we're setting on
  # the first time we saw it again... which should be after we calculate period
  def first_recurrence
    @numbers_by_state[@state.rocks]
  end

  def states_seen
    @states_by_number.size
  end

  def next_state
    state = @state
    %i[north west south east].each { |direction| state = state.tilt(direction) }

    state
  end

  def record
    @numbers_by_state[@state.rocks] = states_seen
    @states_by_number << @state
  end

  def seen?
    # _debug("checking if seen", rocks: @numbers_by_state.values)
    @numbers_by_state.has_key?(@state.rocks)
  end

  def platform
    Platform.new(rocks)
  end

  def rocks
    @text.split("\n").map { |row| row.chars }
  end
end

class Platform
  attr_reader :rocks
  def initialize(rocks)
    @rocks = rocks
  end

  def tilt(direction = :north)
    case direction
    when :west
      tilt_left if direction == :west
    when :north
      rotate(3).tilt_left.rotate
    when :east
      rotate(2).tilt_left.rotate(2)
    when :south
      rotate.tilt_left.rotate(3)
    end
  end

  def rotate(n = 1)
    rotate = @rocks
    n.times { rotate = rotate.matrix_rotate }
    Platform.new(rotate)
  end

  def tilt_left
    Platform.new(@rocks.map { |row| RockRow.new(row).slide })
  end

  def total_load(direction = :north)
    case direction
    when :north
      rotate(1).east_load
    when :east
      east_load
    when :south
      rotate(3).east_load
    when :west
      rotate(2).east_load
    end
  end

  def east_load
    @load = 0
    @rocks.each do |row|
      row.each_with_index { |rock, index| @load += (index + 1) if rock == "O" }
    end

    @load
  end

  def show
    @rocks.each do |row|
      row.each { |ch| print ch }
      puts
    end
    nil
  end
end

class RockRow
  def initialize(rocks)
    @rocks = rocks
  end

  def slide
    @cursor, @row = 0, []
    slide_one until @cursor == @rocks.size
    fill_spaces

    @row
  end

  def slide_one
    case current
    when "."
    when "#"
      reset_base
    when "O"
      roll_rock_onto_stack
    else
      raise "Unknown current #{current}"
    end

    @cursor += 1
  end

  def reset_base
    @row << "." until @row.size == @cursor
    @row << "#"
    @base = @cursor
  end

  def roll_rock_onto_stack
    @row << "O"
  end

  def fill_spaces
    @row << "." until @row.size == @rocks.size
  end

  def current
    @rocks[@cursor]
  end
end
