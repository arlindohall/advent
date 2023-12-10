def solve(input = read_input) =
  CamelCards.new(input).then { |it| [it.total_winnings, it.joker_winnings] }

# too low: 245316597
# just right: 245461700
# too high: 246542064

class CamelCards
  def initialize(text)
    @text = text
  end

  def joker_winnings
    ranked_jokers
      .each_with_index
      .map { |joker, index| joker.bid * (index + 1) }
      .sum
  end

  def ranked_jokers
    joker_hands.sort_by { |hand| hand.rank_str }
  end

  def joker_hands
    @text
      .split("\n")
      .map do |line|
        JokerHand.new(line.split.first, line.split.second, CardWithJoker)
      end
  end

  def total_winnings
    ranked_hands
      .each_with_index
      .map { |hand, index| hand.bid * (index + 1) }
      .sum
  end

  def ranked_hands
    hands.sort_by { |hand| hand.rank_str }
  end

  def hands
    @text
      .split("\n")
      .map { |line| Hand.new(line.split.first, line.split.second) }
  end
end

class Hand
  TYPES = %i[
    high_card
    pair
    two_pair
    three_of_a_kind
    full_house
    four_of_a_kind
    five_of_a_kind
  ]
  RANKS = %w[a b c d e f g]
  TYPE_TO_RANK = TYPES.zip(RANKS).to_h

  attr_reader :bid
  def initialize(cards, bid, card_class = Card)
    @cards = cards.chars.map { |ch| card_class.new(ch) }
    @bid = bid.to_i
  end

  def rank_str
    "#{type_rank}:#{tiebreaker}"
  end

  def type_rank
    TYPE_TO_RANK[type]
  end

  def type
    case
    when five_of_a_kind?
      :five_of_a_kind
    when four_of_a_kind?
      :four_of_a_kind
    when full_house?
      :full_house
    when three_of_a_kind?
      :three_of_a_kind
    when two_pair?
      :two_pair
    when pair?
      :pair
    else
      :high_card
    end
  end

  [[:five, 5], [:four, 4], [:three, 3]].each do |name, n|
    define_method("#{name}_of_a_kind?") do
      groups.any? { |_name, count| count == n }
    end
  end

  def full_house?
    three_of_a_kind? && pair?
  end

  def two_pair?
    groups.count { |_name, count| count == 2 } == 2
  end

  def pair?
    groups.any? { |_name, count| count == 2 }
  end

  def groups
    @cards.count_by { |card| card.rank }
  end

  def tiebreaker
    @cards.map(&:rank).join
  end

  def cards
    @cards.map { |card| card.name }.join
  end
end

class JokerHand < Hand
  def groups
    with_jokers_subbed.count_by { |card| card.rank }
  end

  def with_jokers_subbed
    without_jokers + subbed_jokers
  end

  def without_jokers
    @cards.reject { |card| card.name == "J" }
  end

  def subbed_jokers
    (most_common_non_joker * joker_count).chars.map { |c| CardWithJoker.new(c) }
  end

  def most_common_non_joker
    without_jokers
      .count_by { |card| card.name }
      .max_by { |_, count| count }
      &.first || "A"
  end

  def joker_count
    @cards.count - without_jokers.count
  end
end

class Card
  CARDS = %w[2 3 4 5 6 7 8 9 T J Q K A]
  RANKS = %w[a b c d e f g h i j k l m]

  CARD_TO_RANK = CARDS.zip(RANKS).to_h
  RANK_TO_CARD = RANKS.zip(CARDS).to_h

  attr_reader :name
  def initialize(name)
    @name = name
  end

  def rank
    CARD_TO_RANK[@name]
  end
end

class CardWithJoker
  CARDS = %w[J 2 3 4 5 6 7 8 9 T Q K A]
  RANKS = %w[a b c d e f g h i j k l m]

  CARD_TO_RANK = CARDS.zip(RANKS).to_h
  RANK_TO_CARD = RANKS.zip(CARDS).to_h

  attr_reader :name
  def initialize(name)
    @name = name
  end

  def rank
    CARD_TO_RANK[@name]
  end
end
