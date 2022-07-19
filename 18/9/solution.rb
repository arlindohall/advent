
$debug = false

class MarbleGame
  def initialize(players, marbles)
    @players = Array.new(players, 0)
    @marbles = marbles
  end

  def play
    @turn, @player, @circle = 1, 0, [0]
    until @turn > @marbles
      debug
      place_marble
      next_turn
    end

    @players.max
  end

  def debug
    puts "[#{(@player + 1).to_s}]".ljust(4) + "#{@circle}" if $debug
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
