$_debug = false

def solve
  [Game.new(read_input).play, Game.new(read_input).play_recursive]
end

class Game < Struct.new(:text)
  def players
    @players ||= text.split("\n\n").map { |block| Player.new(block) }
  end

  def play
    round until players.any?(&:out?)

    score
  end

  def play_recursive
    p1, p2 = players.map(&:cards)
    RecursiveGame
      .new(p1, p2, Set[])
      .play
      .then do |p1, p2|
        unless p1 == 0 || p2 == 0
          raise "Should only have one winner (#{p1}, #{p1})"
        end
        p1 + p2
      end
  end

  private

  def round
    _debug(player1: players.first.cards, player2: players.second.cards)
    c1 = players.first.draw!
    c2 = players.second.draw!

    players.first << c1 << c2 if c1 > c2

    players.second << c2 << c1 if c2 > c1
  end

  def score
    players.first.out? ? players.second.score : players.first.score
  end

  class RecursiveGame < Struct.new(:p1_cards, :p2_cards, :games, :level)
    def play
      round until either_out? || seen?

      [score(p1_cards), score(p2_cards)]
    end

    def round
      _debug(p1_cards:, p2_cards:, game_count: games.size, level:)
      games << self
      c1 = p1_cards.shift
      c2 = p2_cards.shift

      if p1_wins?(c1, c2)
        _debug("p1 wins", level:)
        p1_cards << c1 << c2
      else
        _debug("p2 wins", level:)
        p2_cards << c2 << c1
      end
    end

    def p1_wins?(c1, c2)
      return subgame(c1, c2) if enough_cards_for_subgame?(c1, c2)

      c1 > c2
    end

    def enough_cards_for_subgame?(c1, c2)
      p1_cards.size >= c1 && p2_cards.size >= c2
    end

    def subgame(c1, c2)
      p1_sub_cards, p2_sub_cards = copy(c1, c2).play

      return p2_sub_cards.zero? || ended_early?(p1_sub_cards, p2_sub_cards)
    end

    def ended_early?(p1, p2)
      return false if p1.zero?
      return false if p2.zero?

      true
    end

    def either_out?
      p1_cards.empty? || p2_cards.empty?
    end

    def seen?
      games.include?(self)
    end

    def score(cards)
      cards.reverse.each_with_index.map { |card, idx| card * (idx + 1) }.sum
    end

    def copy(n_cards_1, n_cards_2)
      RecursiveGame.new(
        p1_cards.take(n_cards_1),
        p2_cards.take(n_cards_2),
        games,
        (level || 0) + 1
      )
    end
  end

  class Player < Struct.new(:block)
    def out?
      cards.empty?
    end

    def draw!
      cards.shift
    end

    def <<(card)
      _debug(adding_card: card, to_deck: name, having: cards)
      cards << card
      self
    end

    def score
      cards.reverse.each_with_index.map { |card, idx| card * (idx + 1) }.sum
    end

    def name
      block.split(":").first
    end

    def cards
      @cards ||= block.split(":").second.split.map(&:to_i)
    end
  end
end
