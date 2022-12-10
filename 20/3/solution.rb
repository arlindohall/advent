
class Search < Struct.new(:paths, :slope)
  def product
    all_trees.reduce(&:*)
  end

  def all_trees
    sleds.map(&:trees)
  end

  def sleds
    paths.map { |pth| sled(pth) }
  end

  def sled(path)
    Sled.new(path.right, path.down, slope)
  end

  def self.from(text)
    Search.new(
      [
        Direction.new(1, 1),
        Direction.new(3, 1),
        Direction.new(5, 1),
        Direction.new(7, 1),
        Direction.new(1, 2),
      ],
      Slope.from(text)
    )
  end

  class Direction < Struct.new(:right, :down) ; end
end

class Sled < Struct.new(:right, :down, :slope)
  def trees
    path.count { |x, y| slope.collide?(x, y) }
  end

  def path
    @path ||= count_by(rows, down).map { |y, idx| [right * idx, y] }
  end

  def count_by(rows, down)
    result = []
    idx = 0
    1.upto(rows) do |i|
      next if i % down != 0
      idx += 1
      result << [i, idx]
    end
    result
  end

  def debug
    0.upto(rows) do |y|
      # 0.upto(slope.period-1) do |x|
      0.upto(rows * right) do |x|
        if path.include?([x, y])
          print slope.collide?(x, y) ? 'X' : 'O'
        else
          print slope.point(x, y)
        end
      end
      puts
    end
  end

  def rows
    @rows ||= slope.height-1
  end

  def self.from(text, right: 3, down: 1)
    Sled.new(right, down, Slope.from(text))
  end
end

class Slope < Struct.new(:graph)
  def collide?(x, y)
    point(x, y) == '#'
  end

  def point(x, y)
    graph[y][x % period]
  end

  def period
    @period ||= graph.first.size
  end

  def height
    @height ||= graph.size
  end

  def self.from(text)
    new(text.split("\n").map(&:chars))
  end
end

def solve
  [
    Sled.from(read_input).trees,
    Search.from(read_input).product,
  ]
end