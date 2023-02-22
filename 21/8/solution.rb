def solve =
  [
    DisplayInput.parse(read_input).count_determinable_numbers,
    DisplayInput.parse(read_input).sum_outputs
  ]

class DisplayInput
  attr_reader :displays
  def initialize(displays)
    @displays = displays
  end

  def count_determinable_numbers
    displays.map(&:determinable_numbers).sum
  end

  def sum_outputs
    displays.map(&:value).sum
  end

  def self.parse(text)
    new(text.gsub("|\n", "| ").split("\n").map { |slice| Display.new(slice) })
  end

  class Display
    attr_reader :input, :output
    def initialize(line)
      line = line.split(" |")
      @input = line.first.split.map(&:chars).map(&:to_set)
      @output = line.second.split.map(&:chars).map(&:to_set)
    end

    # 1, 4, 7, 8; only in output
    def determinable_numbers
      output.count { |op| one_four_seven_eight.include?(op) }
    end

    def value
      output.map { |num| numeric(num) }.join.to_i
    end

    def numbers
      [zero, one, two, three, four, five, six, seven, eight, nine].map(
        &:sort
      ).map(&:join)
    end

    # private

    def numeric(num)
      numbers.index(num.sort.join).to_s
    end

    def one_four_seven_eight
      @ofse ||= [one, four, seven, eight]
    end

    def one
      input.only! { |ch| ch.size == 2 }
    end

    def four
      input.only! { |ch| ch.size == 4 }
    end

    def seven
      input.only! { |ch| ch.size == 3 }
    end

    def eight
      input.only! { |ch| ch.size == 7 }
    end

    def four_leg
      four - one
    end

    def bottom_leg
      eight - four - top
    end

    def top
      seven - one
    end

    def middle
      eight - zero
    end

    def left_side
      (four_leg - middle) + (eight - nine)
    end

    def zero
      zero_six_nine.only! { |num| four_leg.include?((eight - num).only!) }
    end

    def nine
      zero_six_nine.only! { |num| bottom_leg.include?((eight - num).only!) }
    end

    def six
      (zero_six_nine - [zero, nine]).only!
    end

    def three
      eight - left_side
    end

    def two
      two_five.only! { |num| (four_leg - (eight - num)).size == 1 }
    end

    def five
      two_five.only! { |num| (bottom_leg - (eight - num)).size == 1 }
    end

    def zero_six_nine
      input.filter { |num| num.size == 6 }
    end

    def two_three_five
      input.filter { |num| num.size == 5 }
    end

    def two_five
      two_three_five - [three]
    end
  end
end
