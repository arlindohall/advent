$_debug = false

def solve(input = nil) =
  [
    Tetris.parse(input || read_input).play!,
    Tetris.parse(input || read_input).play!(1_000_000_000_000)
  ]

class Tetris
  shape :instructions

  SHAPES = [
    [[2, 0], [3, 0], [4, 0], [5, 0]],
    [[2, 1], [3, 1], [4, 1], [3, 0], [3, 2]],
    [[2, 0], [3, 0], [4, 0], [4, 1], [4, 2]],
    [[2, 0], [2, 1], [2, 2], [2, 3]],
    [[2, 0], [3, 0], [2, 1], [3, 1]]
  ]

  attr_reader :step, :pieces, :inner_step, :falling
  def play!(limit = 2022)
    @step ||= 0
    @inner_step ||= 0
    @pieces ||= Set[]

    drop_all(limit)
  end

  def drop_all(limit)
    loop do
      return top + 1 if step == limit

      return shortcut(limit) if seen_at(step, inner_step)

      @falling = shape
      drop_one
      debug
      falling.each { |point| pieces << point }
      @step += 1
    end
  end

  def shortcut(block_limit)
    first_occurance_blocks, first_occurance_height = seen_at(step, inner_step)
    second_occurance_blocks = step
    second_occurance_height = top + 1
    one_cycle_blocks = second_occurance_blocks - first_occurance_blocks

    one_cycle_height = second_occurance_height - first_occurance_height
    number_of_whole_cycles =
      (block_limit - first_occurance_blocks) / one_cycle_blocks

    leftover_blocks = (block_limit - first_occurance_blocks) % one_cycle_blocks
    height_of_leftover_blocks =
      height_at(leftover_blocks + first_occurance_blocks) -
        first_occurance_height

    _debug(
      first_occurance_blocks:,
      first_occurance_height:,
      second_occurance_blocks:,
      second_occurance_height:,
      one_cycle_blocks:,
      one_cycle_height:,
      number_of_whole_cycles:,
      leftover_blocks:,
      height_of_leftover_blocks:
    )
    first_occurance_height + (one_cycle_height * number_of_whole_cycles) +
      (height_of_leftover_blocks)
  end

  def height_at(blocks)
    Tetris.new(instructions: instructions).play!(blocks)
  end

  def seen_at(step, inner_step)
    points = ceiling
    return false if points.nil?

    key = [
      normalize(points),
      step % SHAPES.size,
      inner_step % instructions.size
    ]

    @seen ||= {}
    return @seen[key] if @seen[key]

    @seen[key] = [step, top + 1]
    false
  end

  def ceiling
    pieces.group_by(&:first).map(&:second).map(&:max)
  end

  def normalize(points)
    ymin = points.map(&:last).min || 0

    scale(points, -ymin)
  end

  def drop_one
    def d(&block)
      debug

      l = block.call
      return true if intersect?(l)

      @falling = l

      false
    end

    loop do
      d { lateral(falling) }

      @inner_step += 1

      return if d { scale(falling, -1) }
    end
  end

  def jet
    instructions[inner_step % instructions.size]
  end

  def shape
    scale(SHAPES[step % SHAPES.size], top + 4)
  end

  def top
    pieces.map(&:second).max || -1
  end

  def intersect?(points)
    points.any? { |point| pieces.include?(point) } ||
      points.any? { |point| point.last < 0 }
  end

  def scale(points, shift)
    points.map do |point|
      x, y = point
      [x, y + shift]
    end
  end

  def lateral(points)
    shift =
      case jet
      when ">"
        1
      when "<"
        -1
      else
        raise "Unknown instruction: #{jet}"
      end

    shifted =
      points.map do |point|
        x, y = point
        [x + shift, y]
      end

    if shifted.any? { |point| point.first < 0 || point.first > 6 }
      points
    else
      shifted
    end
  end

  def debug
    return unless $_debug
    (top + 6).downto(0) do |y|
      print "|"
      0.upto(6) do |x|
        if pieces.include?([x, y])
          print "#"
        elsif falling.include?([x, y])
          print "@"
        else
          print "."
        end
      end
      puts "|"
    end
    puts "+-------+"
    puts
  end

  class << self
    def parse(text)
      new(instructions: text)
    end
  end
end
