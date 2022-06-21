
class Elephant
  def initialize(size)
    @elves = 1.upto(size).to_a
    @taker = 0
    @index = 0
  end

  def play
    @remaining = @elves.size
    until @remaining == 1
      remove_next
      next_taker
    end

    find_next
    current
  end

  def remove_next
    @index = @taker
    skip_half
    delete_one
  end

  def skip_half
    @searching = 0
    while searching?
      find_next
      @searching += 1
    end
  end

  def searching?
    @searching < half
  end

  def half
    @remaining / 2
  end

  def find_next
    increment
    while current.nil?
      increment
    end
  end

  def increment
    @index = (@index + 1) % @elves.size
  end

  def delete_one
    @remaining -= 1
    puts "Remaining elves: #{@remaining} deleted=#{@elves[@index]}"
    @elves[@index] = nil
  end

  def current
    @elves[@index]
  end

  def next_taker
    increment_taker
    while @elves[@taker].nil?
      increment_taker
    end
  end

  def increment_taker
    @taker = (@taker + 1) % @elves.size
  end
end

@example = Elephant.new(5)
@input = Elephant.new(3018458)
