
$MEMO ||= {1 => [1]}

House = Struct.new(:number)
class House
  def presents
    @presents ||= visitors.sum * 10
  end

  def part2_presents
    @presents ||= part2_visitors.sum * 11
  end

  def visitors
    factors(number).uniq
  end

  def part2_visitors
    factors(number).uniq.filter{ |fact| fact * 50 >= number }
  end

  def factors(num)
    return $MEMO[num] if $MEMO[num]

    2.upto(num/2) do |i|
      if num % i == 0
        other_factors = factors(num/i) + factors(num/i).map{ |f| f * i }
        return $MEMO[num] = [1, i, num/i, *other_factors, num].sort
      end
    end

    $MEMO[num] = [1, num]
  end

  # def factors(num)
  #   $MEMO[num] ||= 1.upto(num/2).filter do |i|
  #     num % i == 0
  #   end
  # end

  # def factors(num)
  #   return $MEMO[num] if $MEMO[num]
  #   for i in (Math.sqrt(num).ceil).downto(2)
  #     if num % i == 0
  #       $MEMO[num/i] ||= factors(num/i)
  #       return ([1] + [i] + $MEMO[num/i] + [num]).uniq
  #     end
  #   end
  #   $MEMO[num] ||= ([1, num]).uniq
  # end
end

class Solution
  DESIRED_SCORE = 36000000
  def part1
    # Solution converges to 24.9*number
    min, med, max = [
      0, 2000000, 5000000
    ]
    binary_search(min, med, max) do |number|
      memo[number] ||= House.new(number).presents
    end
  end

  # attempt 4
  # checkpoint 2122000
  def part1_exhaustive
    0.upto(3598144).lazy.map do |number|
    # 3400000.upto(3540000).lazy.map do |number|
      puts number if number % 1000 == 0
      House.new(number)
    end.filter{ |house| house.presents >= DESIRED_SCORE }.first.number
  end

  def part1_clever_exhaustive
    target_scaled = DESIRED_SCORE/10
    # must at least be sqrt of goal because it is sum of factors
    # divide by 2 because you also add points for self
    # ((Math.sqrt(target_scaled).ceil / 2).ceil)
    #   .upto(DESIRED_SCORE / 2) do |house|
    (target_scaled/5).floor.upto(5000000) do |house|
        puts "Checking house #{house}" if house % 1000 == 0
        return "Solution: #{house}" if House.new(house).presents >= DESIRED_SCORE
      end
  end

  def part2_clever_exhaustive
    target_scaled = DESIRED_SCORE/10
    # must at least be part1 answer
    (831600).floor.upto(5000000) do |house|
        puts "Checking house #{house}" if house % 1000 == 0
        return "Solution: #{house}" if House.new(house).part2_presents >= DESIRED_SCORE
      end
  end

  def memo
    @memo ||= {}
  end

  def binary_search(start, mid, finish, &block)
    return start if start == finish || mid == start
    return finish if mid == finish
    if block.call(mid) < DESIRED_SCORE
      puts "Searching for #{start}, #{mid}, #{finish}... Not yet..."
      binary_search(mid, (mid+finish)/2, finish, &block)
    elsif block.call(mid) > DESIRED_SCORE
      puts "Searching for #{start}, #{mid}, #{finish}... Found!"
      binary_search(start, (mid+start)/2, mid, &block)
    end
  end
end

# with config gives 10350000
# min, med, max = [
#   10, 30, 50 # magic numbers found by running multiple binary searches near 25x
# ].map{|i| (DESIRED_SCORE/i).to_i}.sort
# website says this is too high
@solution = Solution.new

# product of integers 1...n until is big enough
def part1_attempt2
  sum = 0
  index = 0
  magic_number = 1
  while sum < Solution::DESIRED_SCORE
    index += 1
    magic_number *= index
    sum += magic_number * 10
  end
  magic_number
end

# first power of two that is big enough
def part1_attempt3
  sum = 0
  magic_number = 1
  while sum < Solution::DESIRED_SCORE
    magic_number *= 2
    sum = House.new(magic_number).presents
  end
  magic_number
end

# wow this puzzle sucks too
# I think it's smaller than...
# 2399998
# 2400014
# 3628800 <- smallest factorial
#
# at this point I updated the factoring logic to be combinations
# of prime factors multiplied together
# 831600 <- smallest yet but is it real?

# (1..).each do |i|
#   product = 1.upto(i).reduce(&:*)
#   if House.new(product).presents > 36000000
#     puts "Solution: #{product}, #{i}"
#     break
#   end
# end

# ACTUALLY WORKS FOR PART 1
# puts @solution.part1_clever_exhaustive

puts @solution.part2_clever_exhaustive