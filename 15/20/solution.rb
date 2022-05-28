
House = Struct.new(:number)
class House
  def presents
    @presents ||= visitors.sum * 10
  end

  def visitors
    1.upto(Math.sqrt(number) + 1).map do |elf|
      if number % elf == 0
        elf
      end
    end.reject(&:nil?) + [number]
  end
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
    # 0.upto(3598144).lazy.map do |number|
    3400000.upto(3540000).lazy.map do |number|
      puts number if number % 1000 == 0
      House.new(number)
    end.filter{ |house| house.presents >= DESIRED_SCORE }.first.number
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
