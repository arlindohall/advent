
class Search < Struct.new(:paths, :slope)
  # 2772403200 too high??
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
    1.upto(slope.height-1)
      .map { |y| [right * y, y] }
  end

  def self.from(text)
    Sled.new(3, 1, Slope.from(text))
  end
end

class Slope < Struct.new(:graph)
  def collide?(x, y)
    graph[y][x % period] == '#'
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