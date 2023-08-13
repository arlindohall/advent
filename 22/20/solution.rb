def solve(input = read_input) =
  [Mixer.parse(input).grove_sum!, Mixer.parse(input).keyed_grove_sum!]

class Mixer
  KEY = 811_589_153

  shape :numbers

  class << self
    def parse(text)
      new(numbers: text.split.map(&:to_i))
    end
  end

  def grove_sum!
    mix!
    grove_coordinates.sum
  end

  def keyed_grove_sum!
    @numbers = numbers.map { |n| n * KEY }
    10.times do |n|
      mix!
      # puts "Mixing 10 times (#{n}/10)"
    end
    grove_coordinates.sum
  end

  def mix!
    numbers.each_with_index { |num, index| mix_one(num, index) }
  end

  def grove_coordinates
    idx_zero = decrypted.scan { |it| it[:num] == 0 }

    [
      decrypted.skip(1000),
      decrypted.skip(1000),
      decrypted.skip(1000)
    ].tap { |it| p(it:) }.map { |hash| hash[:num] }
  end

  def mix_one(num, index)
    # _debug("mixing list", decrypted: decrypted.to_a.map { |h| h[:num] })
    decrypted.remove({ num:, index: })
    # _debug("removed #{num}", decrypted: decrypted.to_a.map { |h| h[:num] })
    decrypted.skip(num)
    # _debug("skipped #{num}", decrypted: decrypted.to_a.map { |h| h[:num] })
    decrypted.insert({ num:, index: })
    # _debug("done mixing", decrypted: decrypted.to_a.map { |h| h[:num] })
  end

  def decrypted
    @decrypted ||=
      numbers
        .each_with_index
        .map { |num, index| { num:, index: } }
        .to_linked_list
  end
end
