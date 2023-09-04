$_debug = false

class DiffusionMap
  shape :elves

  def self.parse(text)
    new(elves: elves(text).compact.to_set)
  end

  def self.elves(text)
    text
      .split("\n")
      .each_with_index
      .flat_map do |line, y|
        line.chars.each_with_index.map { |char, x| [x, y] if char == "#" }
      end
  end

  def check
    10.times { round }
    debug

    xmin, xmax, ymin, ymax = bounds
    (xmax - xmin + 1) * (ymax - ymin + 1) - elves.size
  end

  def first_round
    count = 1
    until round == 0
      count += 1
      debug if count % 100 == 0
      puts count if count % 100 == 0
    end

    count
  end

  def round
    old_elves, @elves = @elves, moved_elves
    @directions = directions.rotate

    (old_elves - @elves).size
  end

  def debug
    return unless $_debug

    xmin, xmax, ymin, ymax = bounds
    xmin, xmax, ymin, ymax = [xmin - 1, xmax + 1, ymin - 1, ymax + 1]

    (ymin..ymax).map do |y|
      (xmin..xmax).map { |x| print elves.include?([x, y]) ? "#" : "." }
      puts
    end
  end

  private

  def moved_elves
    moves
      .map do |position, elves|
        next elves if elves.size > 1
        [position]
      end
      .flatten(1)
      .to_set
  end

  def moves
    elves.group_by { |elf| proposal(elf) }
  end

  def proposal(elf)
    return elf if no_neighbors?(elf)

    proposed_move(elf) || elf
  end

  def proposed_move(elf)
    directions
      .find { |direction| can_move?(elf, direction) }
      .option_map { |direction| move(elf, direction) }
  end

  def no_neighbors?(elf)
    neighbors(elf).none? { |position| elves.include?(position) }
  end

  def neighbors(elf)
    x, y = elf
    [
      [x - 1, y - 1],
      [x - 1, y],
      [x - 1, y + 1],
      [x, y - 1],
      [x, y + 1],
      [x + 1, y - 1],
      [x + 1, y],
      [x + 1, y + 1]
    ]
  end

  def directions
    @directions ||= %i[north south west east]
  end

  def can_move?(elf, direction)
    to_move(elf, direction).none? { |position| elves.include?(position) }
  end

  def to_move(elf, direction)
    x, y = elf

    case direction
    when :north
      [[x - 1, y - 1], [x, y - 1], [x + 1, y - 1]]
    when :south
      [[x - 1, y + 1], [x, y + 1], [x + 1, y + 1]]
    when :east
      [[x + 1, y - 1], [x + 1, y], [x + 1, y + 1]]
    when :west
      [[x - 1, y - 1], [x - 1, y], [x - 1, y + 1]]
    end
  end

  def move(elf, direction)
    x, y = elf

    case direction
    when :north
      [x, y - 1]
    when :south
      [x, y + 1]
    when :east
      [x + 1, y]
    when :west
      [x - 1, y]
    end
  end

  def bounds
    xmin, xmax = elves.to_a.map(&:first).minmax
    ymin, ymax = elves.to_a.map(&:second).minmax

    [xmin, xmax, ymin, ymax]
  end
end
