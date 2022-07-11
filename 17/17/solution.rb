
class SpinLock
  def initialize(steps)
    @steps = steps
    @buffer = [0]
    @i = 0
  end

  def dup
    self.class.new(@steps)
  end

  def solve
    [dup.part1, dup.part2]
  end

  def part1
    2017.times { cycle }
    find(2017)
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

  def part2
    @insert_at = 0
    @next_char = 0
    50000000.times { simulate }

    @next_char
  end

  <<-docs
    Simulate could be used to find the number that goes after 2017
    in part1 as well, we'd just also need to track the location of
    the number of interest (2017), which we don't need here since
    we only care about 0.
  docs
  def simulate
    p self if @i % 10000000 == 0
    @i += 1
    @insert_at = (@insert_at + @steps) % @i
    @next_char = @i if @insert_at == 0
    @insert_at += 1
  end
end