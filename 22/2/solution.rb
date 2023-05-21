class RockPaperScissors
  shape :rounds

  def self.parse(text)
    text.split("\n").map(&:split).then { |it| new(rounds: it) }
  end

  def score
    scores.sum
  end

  def strategy_score
    strategy_scores.sum
  end

  def scores
    rounds.map { |r| round_score(r) }
  end

  def strategy_scores
    rounds.map { |r| strategy_round_score(r) }
  end

  def strategy_round_score(r)
    opp, strategy = r

    player = to_win(opp, strategy)

    player_score(player) + opp_score(opp, player)
  end

  # X=>LOSE Y=>DRAW Z=>WIN
  STRATEGIES = {
    %w[A X] => "Z",
    %w[A Y] => "X",
    %w[A Z] => "Y",
    %w[B X] => "X",
    %w[B Y] => "Y",
    %w[B Z] => "Z",
    %w[C X] => "Y",
    %w[C Y] => "Z",
    %w[C Z] => "X"
  }
  def to_win(opp, strategy)
    STRATEGIES[[opp, strategy]]
  end

  def round_score(r)
    opp, player = r

    player_score(player) + opp_score(opp, player)
  end

  SCORES = { "X" => 1, "Y" => 2, "Z" => 3 }.freeze
  def player_score(player)
    SCORES[player]
  end

  WINNER = {
    %w[A X] => :draw,
    %w[A Y] => :win,
    %w[A Z] => :lose,
    %w[B X] => :lose,
    %w[B Y] => :draw,
    %w[B Z] => :win,
    %w[C X] => :win,
    %w[C Y] => :lose,
    %w[C Z] => :draw
  }
  def opp_score(opp, player)
    case WINNER[[opp, player]]
    when :win
      6
    when :lose
      0
    else
      3
    end
  end
end
