
class MemoryGame < Struct.new(:starting)
  attr_accessor :next_result, :searching_for, :index
  def answer
    turn(2020)
  end

  def turn(n)
    return starting_turns[n-1] if n <= starting_turns.size

    self.searching_for = starting_turns.last
    self.index = starting_turns.size - 1
    starting_turns.size.upto(n-1) { take_turn }

    next_result
  end

  def take_turn
    # {index:, size: visited.size}.plopp if index % 1_000_000 == 0
    self.next_result = time_since
    visited[searching_for] = index
    self.searching_for = next_result
    self.index += 1
  end

  def time_since
    index - (visited[searching_for] || index)
  end

  def starting_turns
    starting.strip.split(",").map(&:to_i)
  end

  def visited
    @visited ||= starting_turns.each_with_index.to_h
  end
end

def test
  raise unless MemoryGame.new(read_example).answer == 436

  [1, 10, 27, 78, 438, 1836].each_with_index do |n, idx|
    raise [n, idx].to_s unless MemoryGame.new(read_example(idx + 1)).answer == n
  end

  :success
end

def solve
  return MemoryGame.new(read_input).answer, MemoryGame.new(read_input).turn(30000000)
end