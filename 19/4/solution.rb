
class Password
  def initialize(range)
    @range = range
  end

  def count_matches
    range.count { |number|
      valid_password?(number)
    }
  end

  def count_part2_matches
    range.count { |number|
      valid_password?(number, :part2)
    }
  end

  def valid_password?(number, phase = :part1)
    if phase == :part1
      increasing?(number) && repeated?(number)
    else
      increasing?(number) && at_least_one_pair?(number)
    end
  end

  def increasing?(number)
    number = number.to_s
    0.upto(number.length - 2) { |i|
      return false if number[i+1] < number[i]
    }

    true
  end

  def repeated?(number)
    number = number.to_s
    0.upto(number.length - 2) { |i|
      return true if number[i] == number[i+1]
    }

    false
  end

  def at_least_one_pair?(number)
    groups(number).map(&:size).any?(2)
  end

  def groups(number)
    number = number.to_s
    index = 1
    group = [number.chars.first]
    groups = []

    until index == number.length
      if number[index] == group.first
        group << number[index]
      else
        groups << group
        group = [number[index]]
      end
      index += 1
    end

    groups << group
  end

  def range
    low, high = @range.split('-').map(&:to_i)
    low..high
  end
end

def solve
  Password.new(@input).tap { |pw|
    puts [pw.count_matches, pw.count_part2_matches]
  }
end

@input = "137683-596253"