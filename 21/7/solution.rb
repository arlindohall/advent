class Crabs
  attr_reader :positions
  def initialize(positions)
    @positions = positions
  end

  def cost_of_min
    cost_at(min)
  end

  def inc_cost_of_min
    inc_cost_at(min_inc)
  end

  def min
    positions.min.upto(positions.max).min_by { |position| cost_at(position) }
  end

  def min_inc
    positions
      .min
      .upto(positions.max)
      .min_by { |position| inc_cost_at(position) }
  end

  def cost_at(position)
    positions.map { |p| (p - position) }.map(&:abs).sum
  end

  def inc_cost_at(position)
    positions.map { |p| (p - position) }.map(&:abs).map { |d| inc(d) }.sum
  end

  attr_reader :memo
  def inc(n)
    @memo ||= [0, 1]
    return memo[n] if memo[n]
    memo[n] = inc(n - 1) + n
  end

  def self.parse(text)
    new(text.split(",").map(&:to_i))
  end
end
