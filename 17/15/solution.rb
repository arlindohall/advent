
class ModGenerator
  def initialize(generator, mod)
    @generator = generator
    @mod = mod
  end

  def next_value
    @value = @generator.next_value
    until is_mod?
      @value = @generator.next_value
    end

    @value
  end

  def is_mod?
    @value % @mod == 0
  end
end

class Generator
  # Enumerable used to debug/show preview
  include Enumerable

  attr_reader :value, :seed

  LIMIT = 2147483647

  def initialize(seed, factor)
    @seed = seed
    @factor = factor
    @i = 0
  end

  def each
    loop do
      yield next_value
    end
  end

  def next_value
    @value ||= @seed
    @i += 1
    p self if @i % 1_000_000 == 0
    @value = (@value * @factor) % LIMIT
  end
end

class Pair
  attr_reader :a, :b
  def initialize(start)
    @a = Generator.new(start.first, 16807)
    @b = Generator.new(start.last, 48271)
    @a_mod = ModGenerator.new(Generator.new(start.first, 16807), 4)
    @b_mod = ModGenerator.new(Generator.new(start.last, 48271), 8)
  end

  def preview
    @a.take(5).zip(@b.take(5))
      .map{|a, b| pair_to_s(a, b)}
      .each{|s| puts s}
  end

  def pair_to_s(a, b)
    "#{a.to_s.rjust(12)}#{b.to_s.rjust(12)}"
  end

  def solve
    [count_matches, count_strict_matches]
  end

  def count_matches(t=40_000_000)
    @matches = 0
    t.times { check_for_match }
    @matches
  end

  def count_strict_matches(t=5_000_000)
    @strict_matches = 0
    t.times { check_for_strict_match }
    @strict_matches
  end

  def check_for_match
    if bottom_16(@a.next_value) == bottom_16(@b.next_value)
      @matches += 1
    end
  end

  def check_for_strict_match
    if bottom_16(@a_mod.next_value) == bottom_16(@b_mod.next_value)
      @strict_matches += 1
    end
  end

  def bottom_16(num)
    num & 0xffff
  end
end

@example = [65, 8921]
@input = [618, 814]