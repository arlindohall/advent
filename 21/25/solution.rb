def solve = SeaCucumbers.parse(read_input).steps_to_stop

class SeaCucumbers
  shape :easts, :souths, :spaces, :map

  def steps_to_stop
    it = self
    count = 1
    until it.stopped?
      debug!
      count += 1
      it = it.step
    end
    count
  end

  def debug!
    @i ||= 0
    @i += 1
    puts "Step #{@i}" if @i % 50 == 0
  end

  def stopped?
    spaces_east_filled.empty? && spaces_south_filled.empty?
  end

  memoize def step
    move_east.move_south
  end

  def move_east
    SeaCucumbers.new(
      easts: easts - spaces_east_left + spaces_east_filled,
      souths: souths,
      spaces: spaces - spaces_east_filled + spaces_east_left
    )
  end

  def move_south
    SeaCucumbers.new(
      easts: easts,
      souths: souths - spaces_south_left + spaces_south_filled,
      spaces: spaces - spaces_south_filled + spaces_south_left
    )
  end

  memoize def spaces_south_left
    moves_south.map(&:second).to_set
  end

  memoize def spaces_south_filled
    moves_south.map(&:first).to_set
  end

  memoize def spaces_east_left
    moves_east.map(&:second).to_set
  end

  memoize def spaces_east_filled
    moves_east.map(&:first).to_set
  end

  memoize def moves_south
    souths
      .map { |cd| [move(cd, [0, 1]), cd] }
      .filter { |move, cd| spaces.include?(move) }
  end

  memoize def moves_east
    easts
      .map { |cd| [move(cd, [1, 0]), cd] }
      .filter { |move, cd| spaces.include?(move) }
  end

  def move(coordinate, delta)
    x, y = coordinate
    dx, dy = delta
    xmax, ymax = bounds

    [(x + dx) % (xmax + 1), (y + dy) % (ymax + 1)]
  end

  memoize def bounds
    all.to_a.transpose.map { |coords| coords.max }
  end

  def easts
    @easts ||= map.map { |coord, space| coord if space == ">" }.compact.to_set
  end

  def souths
    @souths ||= map.map { |coord, space| coord if space == "v" }.compact.to_set
  end

  def spaces
    @spaces ||= map.keys.to_set - souths - easts
  end

  def all
    easts + souths + spaces
  end

  def ==(sea_cucumbers)
    easts == sea_cucumbers.easts && souths == sea_cucumbers.souths &&
      spaces == sea_cucumbers.spaces
  end

  def dup
    SeaCucumbers.new(easts: easts.dup, souths: souths.dup, spaces: spaces.dup)
  end

  class << self
    def parse(text)
      text
        .split("\n")
        .each_with_index
        .flat_map do |line, y|
          line.chars.each_with_index.map { |char, x| [[x, y], char] }
        end
        .to_h
        .then { |map| new(map:) }
    end
  end
end
