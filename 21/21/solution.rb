def solve =
  [DiracDice.new(read_input).play!, DiracDice.new(read_input).play_dirac!]

class DiracDice
  def initialize(text)
    @text = text
  end

  def play_dirac!
    winning_universes.max
  end

  def winning_universes
    [
      wins(
        turn: 0,
        p1_score: 0,
        p2_score: 0,
        p1_pos: players.first.position,
        p2_pos: players.second.position
      ),
      wins(
        # where the second player wins
        # (but still goes second because turn == 1)
        # i.e. swap winner
        turn: 1,
        p1_score: 0,
        p2_score: 0,
        p1_pos: players.second.position,
        p2_pos: players.first.position
      )
    ]
  end

  memoize def wins(turn:, p1_score:, p2_score:, p1_pos:, p2_pos:)
    # {
    #   turn: turn,
    #   p1_score: p1_score,
    #   p2_score: p2_score,
    #   p1_pos: p1_pos,
    #   p2_pos: p2_pos
    # }.plop
    return 0 if p2_score >= 21
    return 1 if p1_score >= 21

    case turn
    when 0
      dice_rolls
        .map do |roll|
          p1_new_pos = p1_pos + roll
          p1_new_pos %= 10
          p1_new_pos = 10 if p1_new_pos == 0
          wins(
            turn: 1,
            p1_score: p1_score + p1_new_pos,
            p2_score:,
            p1_pos: p1_new_pos,
            p2_pos:
          )
        end
        .sum
    when 1
      dice_rolls
        .map do |roll|
          p2_new_pos = p2_pos + roll
          p2_new_pos %= 10
          p2_new_pos = 10 if p2_new_pos == 0
          wins(
            turn: 0,
            p1_score:,
            p2_score: p2_score + p2_new_pos,
            p1_pos:,
            p2_pos: p2_new_pos
          )
        end
        .sum
    end
  end

  memoize def dice_rolls
    [1, 2, 3].flat_map do |first|
      [1, 2, 3].flat_map do |second|
        [1, 2, 3].flat_map { |third| first + second + third }
      end
    end
  end

  def play!
    player = 0
    until players.any? { |p| p.score >= 1000 }
      players[player].move(roll!, roll!, roll!)
      player = 1 - player
    end

    players.map(&:score).min * rolls
  end

  def dice
    @dice ||= 0
  end

  attr_reader :rolls
  def roll!
    @rolls ||= 0
    @rolls += 1
    if dice == 100
      @dice = 1
    else
      @dice = dice + 1
    end
  end

  def players
    @players ||=
      @text
        .scan(/starting position: (\d)/)
        .map(&:first)
        .map(&:to_i)
        .each_with_index
        .map { |pos, idx| Player.new(id: idx + 1, position: pos) }
        .then { |p1, p2| @p1, @p2 = p1, p2 }
  end

  class Player
    attr_reader :id, :position, :score
    def initialize(**params)
      @id = params[:id]
      @position = params[:position]
      @score = params[:score] || 0
    end

    def move(*numbers)
      @position += numbers.sum
      @position %= 10
      @position = 10 if @position == 0

      @score += @position

      # puts "Player #{id} rolls #{numbers.join("+")} and moves to space " \
      #        "#{position} scoring #{score} points."
    end
  end
end
