$debug = false

class CupCircle < Struct.new(:text)
  def times(n)
    cups
    n.times { round }

    collect_cups
  end

  def collect_cups
    @head = @head.next_cup until @head.name == 1

    str = ""
    @head = @head.next_cup

    until @head.name == 1
      str << @head.name.to_s
      @head = @head.next_cup
    end

    str
  end

  def round
    cups.to_s.plop
    {destination:}.plopp(show_header: false)
    insert
    step
  end

  def destination
    @held, @dest = @head.destination
  end

  def insert
    @held.next_cup.next_cup.next_cup = @dest.next_cup
    @dest.next_cup = @held
  end

  def step
    @head = @head.next_cup
  end

  def cups
    return @head if @head

    @head = Cup.new(text[0].to_i)
    @head.next_cup = @head

    text.chars.drop(1).each do |cup|
      init_insert_cup(Cup.new(cup.to_i))
    end

    @head
  end

  def one_million_cups
    tap do
      @head = Cup.new(text[0].to_i)
      @head.next_cup = @head

      text.chars.drop(1).each do |cup|
        init_insert_cup(Cup.new(cup.to_i))
      end

      10.upto(1_000_000) do |i|
        init_insert_cup(Cup.new(i))
      end
    end

    10_000_000.times { |i| round ; puts i }

    first_two
  end

  def first_two
    find_one.then do |cup|
      cup.next_cup.name * cup.next_cup.next_cup.name
    end
  end

  def find_one
    cup = @head
    cup = cup.next_cup until cup.name == 1
  end

  def init_insert_cup(cup)
    @dest ||= @head
    cup.next_cup = @dest.next_cup
    @dest.next_cup = cup
    @dest = cup
  end

  class Cup < Struct.new(:name, :next_cup)
    def destination
      held = pick_up
      c1, c2, c3 = held.name, held.next_cup.name, held.next_cup.next_cup.name

      target_dest = name - 1
      target_dest %= 9
      target_dest = 9 if target_dest == 0
      until [c1, c2, c3].exclude?(target_dest.plop(prefix: "target_dest: "))
        target_dest -= 1
        target_dest %= 9
        target_dest = 9 if target_dest == 0
      end

      dest = self
      until dest.name == target_dest
        dest = dest.next_cup
        raise "Infinite cycle" if dest == self
        # break if dest == self
      end

      [held, dest]
    end

    def pick_up
      held = next_cup
      self.next_cup = held.next_cup.next_cup.next_cup
      held.next_cup.next_cup.next_cup = nil

      held
    end

    def inspect
      "·#{self.to_s}·"
    end

    def to_s
      str = "#{name} -> "
      printing = next_cup
      until printing == self || printing == nil
        str << "#{printing.name} -> "
        printing = printing.next_cup
      end

      str
    end
  end
end