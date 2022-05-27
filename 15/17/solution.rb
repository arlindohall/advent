
Solution = Struct.new(:containers, :size)
class Solution
  def solve
    @solution ||= 1.upto(containers.size).to_a.flat_map do |num_containers|
      containers.combination(num_containers).to_a
    end.filter do |combination|
      combination.sum == size
    end
  end

  def solve_min
    solve.filter do |solution|
      solution.size == min
    end
  end

  def min
    @min ||= solve.map(&:size).min
  end
end

# @containers = [20, 15, 10, 5, 5]
@containers = %Q(
  43
  3
  4
  10
  21
  44
  4
  6
  47
  41
  34
  17
  17
  44
  36
  31
  46
  9
  27
  38
).strip.lines.map(&:strip).map(&:to_i)

# part1: Solution.new(@containers, 150).solve.count
# part2: Solution.new(@containers, 150).solve_min.count