$_debug = false

def solve(input = read_input) =
  Scratchcards.new(input).then { |sc| [sc.score, sc.score_with_copies] }

class Scratchcards
  def initialize(text)
    @text = text
  end

  def score
    cards.map(&:score).sum
  end

  def score_with_copies
    cards.size.times.map { |index| score_for(index) }.sum
  end

  def cards
    @cards ||= @text.split("\n").map { |line| Card.parse(line) }
  end

  memoize def score_for(index)
    return 0 if index >= cards.size
    _debug "index: #{index}"
    1 + children(@cards[index].matches.size, index)
  end

  def children(score, index)
    scoring_children = (index + 1).upto(score + index)
    _debug "score: #{score}, index: #{index}, children_to_score: #{scoring_children.to_a}}"

    scoring_children
      .map { |i| score_for(i) }
      .sum
      .tap { |it| _debug "score: #{score}, index: #{index}, children: #{it}" }
  end
end

class Card
  def self.parse(line)
    id = line.match(/Card +(\d+)/)[1]
    winners = line.split(":").second.split("|").first.split.map(&:to_i)
    numbers = line.split(":").second.split("|").second.split.map(&:to_i)

    new(id, winners, numbers)
  end

  def initialize(id, winners, numbers)
    @id = id
    @winners = winners
    @numbers = numbers
  end

  def matches
    @winners & @numbers
  end

  def score
    return 0 if matches.size == 0

    2**(matches.size - 1)
  end
end
