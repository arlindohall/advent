$_debug = false

def solve
  [CupCircle.new(read_input).game!, CupCircle.new(read_input).long_game!]
end

class CupCircle < Struct.new(:text)
  attr_reader :next_cup, :current, :insert_point, :picked_up, :insert_after

  def cups!
    @current = text[0].to_i
    @next_cup =
      text
        .chars
        .each_with_index
        .map { |ch, idx| [ch.to_i, text[(idx + 1) % text.size].to_i] }
        .to_h
  end

  def one_million_cups!
    @current = text[0].to_i
    @next_cup = {} # ArrayStore.new may be faster, idk?
    text.chars.each_with_index do |ch, idx|
      next_cup[ch.to_i] = text[(idx + 1) % text.size].to_i
    end

    (text.size + 1).upto(1_000_000) { |i| next_cup[i] = i + 1 }

    next_cup[text[-1].to_i] = text.size + 1
    next_cup[1_000_000] = text[0].to_i
  end

  def game!(rounds = 100)
    cups!
    rounds.times { rotate }
    next_eight
  end

  def long_game!(rounds = 10_000_000)
    one_million_cups!
    rounds.times do |i|
      rotate
      _debug(i) if i % 100_000 == 0
    end
    product
  end

  def rotate
    _debug(next_eight:, next_cup:)
    pick_up_cups
    insert_cups
    progress
  end

  def pick_up_cups
    @picked_up = [follow_cups(1), follow_cups(2), follow_cups(3)]
    next_cup[current] = follow_cups(4)
  end

  def insert_cups
    desired_insert = ((current - 2) % next_cup.size) + 1
    until picked_up.exclude?(desired_insert)
      desired_insert -= 2
      desired_insert %= next_cup.size
      desired_insert += 1
    end

    insert_before = follow_cups(1, desired_insert)
    next_cup[desired_insert] = picked_up.first
    next_cup[picked_up.last] = insert_before

    _debug(picked_up:, current:, desired_insert:, insert_before:)
  end

  def progress
    @current = follow_cups
  end

  def follow_cups(count = 1, insert_after = nil)
    cursor = insert_after || current
    count.times.map { cursor = next_cup[cursor] }

    if cursor.nil?
      raise "Got a nil cursor while following cups: #{{ insert_after: }}"
    end

    cursor
  end

  def next_eight
    cursor = 1
    output = []
    8.times.map do
      cursor = next_cup[cursor]
      output << cursor.to_s
    end
    output.join
  end

  def product
    next_cup[1] * next_cup[next_cup[1]]
  end

  class ArrayStore
    attr_reader :array

    def initialize
      @array = Array.new(1_000_000)
    end

    def [](idx)
      array[idx - 1]
    end

    def []=(idx, val)
      array[idx - 1] = val
    end

    def size
      array.size
    end
  end
end
