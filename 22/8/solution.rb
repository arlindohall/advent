$_debug = true

def solve =
  Forest.parse(read_input).then { |it| [it.count_visible, it.max_scenic] }

class Forest
  shape :trees

  class << self
    def parse(text)
      new(trees: text.split.map(&:chars).sub_map(&:to_i))
    end
  end

  def count_visible
    visible.flatten.sum
  end

  def max_scenic
    scenic_scores.flatten.max
  end

  def scenic_scores
    viewing_distances.sub_map(&:product)
  end

  def viewing_distances
    trees.each_with_index.map do |row, y|
      row.each_with_index.map do |tree, x|
        # next 0 unless visible[y][x].zero?
        viewing_distance(x, y)
      end
    end
  end

  def viewing_distance(x, y)
    [[0, -1], [1, 0], [0, 1], [-1, 0]].map do |dx, dy|
      line_of_sight(x, y, dx, dy)
    end
  end

  def line_of_sight(cx, cy, dx, dy)
    x, y = cx, cy
    highest = 0
    seen = 0

    loop do
      cx += dx
      cy += dy

      # raise "out of bounds" if trees[cy].nil? || trees[cy][cx].nil?
      return seen if trees[cy].nil? || trees[cy][cx].nil? || cy < 0 || cx < 0

      seen += 1
      # seen += 1 if trees[cy][cx] >= highest
      # highest = trees[cy][cx] if trees[cy][cx] > highest

      return seen if trees[cy][cx] >= trees[y][x]
    end
  end

  memoize def visible
    debug(trees)
    highest.each { |it| debug(it) }
    trees
      .each_with_index
      .map do |row, y|
        row.each_with_index.map do |tree, x|
          #  _debug(x:, y:, tree:, los: line_of_sight[y][x])
          if highest.any? { |highest_in_direction|
               tree > highest_in_direction[y][x]
             }
            1
          else
            0
          end
        end
      end
      .tap { |it| debug(it) }
  end

  memoize def highest
    # debug(trees)
    4.times.map { |i| highest_before_rotations(i) }
  end

  def highest_before_rotations(i)
    highest_before(trees.matrix_rotate(i)).matrix_rotate(-i)
    # .tap { |it| debug(it) }
  end

  def highest_before(grid)
    grid.rows.map do |row|
      max = [-1]
      (row.size - 1).times { |i| max << [max.last, row[i]].max }

      max
    end
  end

  def debug(grid)
    return unless $debug
    grid.each do |row|
      row.each { |col| print col }
      puts
    end
    puts
  end
end
