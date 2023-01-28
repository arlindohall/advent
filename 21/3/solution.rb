def solve
  Diagnostic
    .new(read_input)
    .then do |diagnostic|
      [diagnostic.power_consumption, diagnostic.life_support_rating]
    end
end

class Diagnostic
  attr_reader :text

  def initialize(text)
    @text = text
  end

  def power_consumption
    gamma_rate * epsilon_rate
  end

  def gamma_rate
    most_common_bits.join.to_i(2)
  end

  def epsilon_rate
    least_common_bits.join.to_i(2)
  end

  def most_common_bits
    numbers.first.size.times.map { |index| most_common_bit(index) }
  end

  def least_common_bits
    most_common_bits.map { |bit| bit == "0" ? "1" : "0" }
  end

  def most_common_bit(index)
    numbers.map { |num| num[index] }.count_values.max_by(&:last).first
  end

  def life_support_rating
    oxygen_rating * co2_rating
  end

  def oxygen_rating
    rating { |counts| tie?(counts) ? "1" : counts.max_by(&:last).first }
  end

  def co2_rating
    rating { |counts| tie?(counts) ? "0" : counts.min_by(&:last).first }
  end

  def tie?(counts)
    counts.size == 2 && counts.map(&:last).uniq.size == 1
  end

  def rating
    @candidates = numbers
    @index = 0

    until @candidates.size == 1
      bit = yield(@candidates.map { |number| number[@index] }.count_values)
      # { bit:, candidates: @candidates, index: @index }.plop
      reduce_candidates!(bit)
      @index += 1
    end

    @candidates.first.to_i(2)
  end

  def reduce_candidates!(bit)
    @candidates = @candidates.filter { |number| number[@index] == bit }
  end

  def numbers
    text.split
  end
end
