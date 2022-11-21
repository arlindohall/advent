
class Deck
  Card = Struct.new(:value, :next)
  def initialize(cards, size)
    @cards = cards
    @size = size
  end

  def deal_new!
    puts "Reversing deck"
    top = @cards
    new_cards = nil
    until top.nil?
      top, held = top.next, top
      held.next = new_cards
      new_cards = held
    end

    @cards = new_cards
    self
  end

  def cut!(n)
    puts "Cutting deck n/#{n}"
    old_tail = tail
    new_tail = n > 0 ? seek(n) : seek(@size + n)
    old_head = @cards
    # puts "old_tail/#{old_tail.value}, old_head/#{old_head.value}, new_tail/#{new_tail.value}"

    @cards = new_tail.next
    new_tail.next = nil
    old_tail.next = old_head
    # puts "cards/#{@cards.value}, new_tail/#{new_tail.value}, old_tail/#{old_tail.value}"

    self
  end

  def inc!(n)
    puts "Rotating deck n/#{n}"
    idx = 0
    until @cards.nil?
      table[idx] = @cards
      @cards = @cards.next
      idx += n
      idx %= @size
    end

    @cards = Deck.from_array(table)
    self
  end

  def table
    @table ||= Array.new(@size)
  end

  def tail
    seek(@size)
  end

  def seek(n)
    ptr = @cards
    (n-1).times { ptr = ptr.next }
    ptr
  end

  def debug
    p to_array.map { |c| c&.value }
  end

  def to_array
    idx = 0
    ptr = @cards
    until ptr.nil?
      table[idx] = ptr
      ptr = ptr.next
      idx += 1
    end
    table.dup
  end

  def self.of(n)
    cards = 0.upto(n-1).map { |i| Card.new(i, nil) }
    new(from_array(cards), n)
  end

  def self.from_array(ary)
    ary.each_with_index { |c, idx| c.next = ary[idx+1] }
    ary.first
  end
end

class Dealer
  def initialize(instructions, deck)
    @instructions = instructions
    @deck = deck
  end

  def deal
    @instructions.each { |i| i.call(@deck) }

    @deck.to_array.map(&:value)
  end

  class << self
    def parse(text, n = 10007)
      new(
        text.lines.map { |line| parse_line(line) },
        Deck.of(n)
      )
    end

    def parse_line(line)
      case line
      when /deal with/
        inc = line.split.last.to_i
        ->(deck) { deck.inc!(inc) }
      when /deal into/
        ->(deck) { deck.deal_new! }
      when /cut/
        cut = line.split.last.to_i
        ->(deck) { deck.cut!(cut) }
      else
        raise "Unexpected line: #{line}"
      end
    end
  end
end

class FakeDealer
  def initialize(instructions, cards, start = 2020, repititions = 1)
    @instructions = instructions
    @cards = cards
    @start = start
    @repititions = repititions
  end

  # This one is double-stolen, because the guy I copied also copied someone
  # https://todd.ginsberg.com/post/advent-of-code/2019/day22/
  # Got 53585064890592, too high
  def deal
    @factor, @addend = 1, 0
    @instructions.reverse.each { |type, arg| follow_one(type, arg) }

    @power = @factor.pow(@repititions, @cards)

    final_position % @cards
  end

  def follow_one(type, arg)
    case type
    when :cut
      @addend += arg
    when :inc
      val = arg.pow(@cards - 2, @cards)
      @factor *= val
      @addend *= val
    when :deal
      @factor = -@factor
      @addend = -@addend - 1
    end
    @factor %= @cards
    @addend %= @cards
  end

  def final_position
    factor_term + (addition_term * mod_term)
  end

  private

  def factor_term
    @power * @start
  end

  def addition_term
    @addend * (@power + @cards - 1)
  end

  def mod_term
    @factor.pow(@cards - 2, @cards)
  end

  class << self
    def parse(text, size = 119315717514047, start = 2020, repititions = 101741582076661)
      new(
        text.lines.map { |line| parse_line(line) },
        size,
        start,
        repititions,
      )
    end

    def parse_line(line)
      case line
      when /deal with/
        inc = line.split.last.to_i
        [:inc, inc]
      when /deal into/
        [:deal]
      when /cut/
        cut = line.split.last.to_i
        [:cut, cut]
      else
        raise "Unexpected line: #{line}"
      end
    end
  end
end

def fake_deal_whole_deck(instructions)
  ary = Array.new(10)
  0.upto(9).each do |i|
    next_idx = FakeDealer.parse(instructions, 10, i, 1).follow_instructions
    ary[next_idx] = i
  end
  ary
end

def test
  examples = [
    @example1, %w(0 3 6 9 2 5 8 1 4 7),
    @example2, %w(3 0 7 4 1 8 5 2 9 6),
    @example3, %w(6 3 0 7 4 1 8 5 2 9),
    @example4, %w(9 2 5 8 1 4 7 0 3 6),
  ]

  examples.each_slice(2) do |input, expected|
    actual = Dealer.parse(input, 10).deal.map(&:to_s)
    raise "Expected #{expected} got #{actual}" unless expected == actual
  end

  examples.each_slice(2) do |input, expected|
    expected = expected.map(&:to_i)
    result = fake_deal_whole_deck(input)
    raise "Expected #{expected} got #{result}" unless expected == result
  end

  :success
end

def solve
  [
    Dealer.parse(@input).deal.index(2019),
    FakeDealer.parse(@input).deal
  ]
end

@example1 = <<-example
deal with increment 7
deal into new stack
deal into new stack
example

@example2 = <<-example
cut 6
deal with increment 7
deal into new stack
example

@example3 = <<-example
deal with increment 7
deal with increment 9
cut -2
example

@example4 = <<-example
deal into new stack
cut -2
deal with increment 7
cut 8
cut -4
deal with increment 7
cut 3
deal with increment 9
deal with increment 3
cut -1
example

@input = <<-example
cut -135
deal with increment 38
deal into new stack
deal with increment 29
cut 120
deal with increment 30
deal into new stack
cut -7198
deal into new stack
deal with increment 59
cut -8217
deal with increment 75
cut 4868
deal with increment 29
cut 4871
deal with increment 2
deal into new stack
deal with increment 54
cut 777
deal with increment 40
cut -8611
deal with increment 3
cut -5726
deal with increment 57
deal into new stack
deal with increment 41
deal into new stack
cut -5027
deal with increment 12
cut -5883
deal with increment 45
cut 9989
deal with increment 14
cut 6535
deal with increment 18
cut -5544
deal with increment 29
deal into new stack
deal with increment 64
deal into new stack
deal with increment 41
deal into new stack
deal with increment 6
cut 4752
deal with increment 8
deal into new stack
deal with increment 26
cut -6635
deal with increment 10
deal into new stack
cut -3830
deal with increment 48
deal into new stack
deal with increment 39
cut -4768
deal with increment 65
deal into new stack
cut -5417
deal with increment 15
cut -4647
deal into new stack
cut -3596
deal with increment 17
cut -3771
deal with increment 50
cut 1682
deal into new stack
deal with increment 20
deal into new stack
deal with increment 22
deal into new stack
deal with increment 3
cut 8780
deal with increment 52
cut 7478
deal with increment 9
cut -8313
deal into new stack
cut 742
deal with increment 19
cut 9982
deal into new stack
deal with increment 68
cut 9997
deal with increment 23
cut -240
deal with increment 54
cut -7643
deal into new stack
deal with increment 6
cut -3493
deal with increment 74
deal into new stack
deal with increment 75
deal into new stack
deal with increment 40
cut 596
deal with increment 6
cut -4957
deal into new stack
example