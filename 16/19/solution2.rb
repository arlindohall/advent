
<<-EXPLANATION
I cheated a little bit to get this by reading reddit for tips. The key
is that you can use two lists instead of one to represent the circle.
Then you rotate through the players, removing the one on the end of the
list, and keep in the middle with a balancing operation.
EXPLANATION
class Elephant
  def initialize(size)
    @left = 1.upto(size/2).to_a
    @right = (size/2+1).upto(size).to_a
  end

  def play
    while remaining != 1
      if remaining % 10000 == 0
        puts "Remaining=#{remaining}"
      end
      balance
      remove
      rotate
    end

    (@right + @left).first
  end

  def remaining
    @left.size + @right.size
  end

  def balance
    until @right.size >= @left.size
      @right.unshift(@left.pop)
    end
  end

  def remove
    @right.shift
  end

  def rotate
    @right.push(@left.shift)
    @left.push(@right.shift)
  end
end

@example = Elephant.new(5)
@input = Elephant.new(3018458)

# 1509229 is too high