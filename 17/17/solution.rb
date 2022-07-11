
class SpinLock
  def initialize(steps)
    @steps = steps
    @buffer = [0]
    @i = 0
  end

  def solve
    2017.times { cycle }
    part1 = find(2017)

    return [part1]
    @i, @buffer = 0, [0]
    50000000.times { cycle }
    part2 = find(0)

    [part1, part2]
  end

  def find(n)
    @buffer[@buffer.index(n) + 1]
  end

  def cycle
    step
    insert
  end

  def step
    @buffer.rotate!(@steps)
  end

  def insert
    @i += 1
    @buffer.rotate!
    @buffer.push(@i)
    @buffer.rotate!(-1)
  end

end