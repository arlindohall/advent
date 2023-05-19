class Monad
  shape :input

  def smallest_valid
    smallest.each { |number| return number if valid?(number) }
  end

  def largest_valid
    largest.each { |number| return number if valid?(number) }
  end

  # largest will be 99999xx9x9xxxx
  def largest
    i = (["9"] * 7).join.to_i
    (
      Enumerator.new do |yielder|
        loop do
          digits = i.digits.reverse
          i -= 1
          next if digits.include?(0)
          yielder.yield(
            [9] * 5 + digits[0..1] + [9] + [digits[2]] + [9] + digits[3..]
          )
        end
      end
    ).lazy
  end

  # largest will be 11111xx1x1xxxx
  def smallest
    i = (["1"] * 7).join.to_i
    (
      Enumerator.new do |yielder|
        loop do
          digits = i.digits.reverse
          i += 1
          next if digits.include?(0)
          yielder.yield(
            [1] * 5 + digits[0..1] + [1] + [digits[2]] + [1] + digits[3..]
          )
        end
      end
    ).lazy
  end

  def valid?(number)
    debug!(number)

    return false if number.include?(0)

    machine.accepts?(number)
  end

  def debug!(number)
    @i ||= 0
    @i += 1
    puts "Iteration #{@i} => #{number}" if @i % 100_000 == 0
  end

  def native_machine
    @native_machine ||= NativeMachine.new(text: @input)
  end

  def machine
    native_machine
    # @machine ||= Machine.new(text: @input)
  end
end

class NativeMachine
  shape :text

  def accepts?(digits)
    digits.each_with_index.all? do |digit, index|
      b(index) > 9 || digit == sum_up_to(digits, index)
    end
  end

  def sum_up_to(digits, index)
    0.upto(index - 1).map { |idx| digits[idx] + c(idx) }
  end

  def b(index)
    groups[index].second
  end

  def c(index)
    groups[index].third
  end

  def _accepts?(digits)
    z = 0
    groups
      .zip(digits)
      .map(&:flatten)
      .each do |args|
        _a, b, c, digit = args
        z = f(z, b, c, digit)
      end
    z == 0
  end

  # w never written to, no need to track
  # x never read from until overwriting with zero each cycle
  # y never read from until overwriting with zero each cycle
  # a is always 26 when b > 9
  def _f(z, b, c, digit)
    z += (digit + c) unless b > 9 || (z % 26 + b) == digit

    # x = ((z % 26 + b) == digit ? 0 : 1)
    # z /= a
    # z *= (25 * x) + 1
    # z += (digit + c) * x

    # z =
    #   ((z / a) * ((25 * ((z % 26 + b) == digit ? 0 : 1)) + 1)) +
    #     (digit + c) * ((z % 26 + b) == digit ? 0 : 1)
  end

  def f(z, a, b, c, digit)
    # second can only be true if b negative because all positive b > 9
    # second must be true if this is a valid number, because 7 up and 7 down by 26x
    if b < 0 && z % 26 + b == digit
      z /= a
    else
      # Only gets bigger or stays same size, a = 26 or a = 1, equals 26 for negatives
      # So this branch must be positives, so a = 1 every time
      # So the value of z used for next condition is (digit + c)
      # Also b doesn't matter for positives
      z /= a # 1
      z *= 26
      z += digit + c
    end
  end

  "
  The strings below are the answer worked out by hand using the algorithm described
  by f above. Basically, multiplying by 26 is a push and dividing is a pop, and we
  can only satisfy the condition on x when the number is negative. Since we need to
  pop all numbers to get back to zero, we have to pop on every negative, meaning each
  negative must satisfy the condition of the popped number, giving the below.
  "

  "
  push 14 + d0
  push 2 + d1
  push 1 + d2
  push 13 + d3
  push 5 + d4
  pop d4, assert d5 == 5 + d4 - 12
  pop d3, assert d6 == 13 + d3 - 12
  push 9 + d7
  pop d7, assert d8 == 9 + d7 - 7
  push 13 + d9
  pop d9, assert d10 == 13 + d9 - 8
  pop d2, assert d11 == 1 + d2 - 5
  pop d1, assert d12 == 2 + d1 - 10
  pop d0, assert d13 == 14 + d0 - 7
  "

  "
  d0: free
  d1: free
  d2: free
  d3: free
  d4: free
  d5  = d4 - 7
  d6  = d3 + 1
  d7: free
  d8  = d7 + 2
  d9: free
  d10 = d9 + 5
  d11 = d2 - 4
  d12 = d1 - 8
  d13 = d0 + 7
  "

  # largest
  "
  d0:  2
  d1:  9
  d2:  9
  d3:  8
  d4:  9
  d5:  2
  d6:  9
  d7:  7
  d8:  9
  d9:  4
  d10: 9
  d11: 5
  d12: 1
  d13: 9
  largest: 29989297949519
  "

  "
  d0: free
  d1: free
  d2: free
  d3: free
  d4: free
  d5  = d4 - 7
  d6  = d3 + 1
  d7: free
  d8  = d7 + 2
  d9: free
  d10 = d9 + 5
  d11 = d2 - 4
  d12 = d1 - 8
  d13 = d0 + 7
  "

  # smallest
  "
  d0: 1
  d1: 9
  d2: 5
  d3: 1
  d4: 8
  d5: 1
  d6: 2
  d7: 1
  d8: 3
  d9: 1
  d10: 6
  d11: 1
  d12: 1
  d13: 8
  smallest: 19518121316118
  "

  def groups
    @groups ||= text.scan(groups_regex).sub_map(&:to_i)
  end

  def groups_regex
    Regexp.new(<<~regex.strip)
      inp w
      mul x 0
      add x z
      mod x 26
      div z (\\d+)
      add x (-?\\d+)
      eql x w
      eql x 0
      mul y 0
      add y 25
      mul y x
      add y 1
      mul z y
      mul y 0
      add y w
      add y (\\d+)
      mul y x
      add z y
    regex
  end
end
