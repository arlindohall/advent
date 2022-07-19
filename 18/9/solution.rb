
$debug = false

class LinkedListQueue

  Node = Struct.new(:value, :next, :prev)

  attr_reader :head

  def initialize(val)
    @head = Node[val]
    @head.next = @head
    @head.prev = @head
  end

  def unshift(val)
    n = Node[val, @head, @head.prev]
    @head.prev.next = n
    @head.prev = n
    @head = n
  end

  def shift
    n = @head
    n.prev.next = n.next
    n.next.prev = n.prev

    @head = n.next
    n.value
  end

  def rotate!(n)
    if n > 0
      n.times { @head = @head.next }
    elsif n < 0
      n.abs.times { @head = @head.prev }
    end
  end

  def to_s
    to_a.inspect
  end

  def to_a
    return [] if @head.nil?
    ptr, a = @head.next, [@head.value]
    until ptr == @head
      a << ptr.value
      ptr = ptr.next
    end
    a
  end
end

class MarbleGame
  def initialize(players, marbles)
    @players = Array.new(players, 0)
    @marbles = marbles
  end

  def play
    @turn, @player, @circle = 1, 0, LinkedListQueue.new(0)
    until @turn > @marbles
      debug
      place_marble
      next_turn
    end

    @players.max
  end

  def debug
    puts "[#{(@player + 1).to_s}]".ljust(6) + "#{@circle.to_a}" if $debug
  end

  def place_marble
    if @turn % 23 == 0
      @circle.rotate!(-7)
      @players[@player] += @turn + @circle.shift
    else
      @circle.rotate!(2)
      @circle.unshift(@turn)
    end
  end

  def next_turn
    @turn += 1
    @player = (@player + 1) % @players.size
  end
end

@example = [
  [9, 25],
  [10, 1618],
  [13, 7999],
  [17, 1104],
  [21, 6111],
  [30, 5807],
]

@input = [427, 70723]
@part2 = [427, 70723 * 100]
