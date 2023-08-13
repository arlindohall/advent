$_debug = false

def solve(input = read_input) = [Mixer.parse(input).grove_sum!]

class Mixer
  shape :numbers

  class << self
    def parse(text)
      new(numbers: text.split.map(&:to_i))
    end
  end

  def grove_sum!
    mix!
    grove_coordinates.tap { |it| p(it:) }.map { |hash| hash[:num] }.sum
  end

  def mix!
    numbers.each_with_index { |num, index| mix_one(num, index) }
  end

  def grove_coordinates
    idx_zero = decrypted.scan { |it| it[:num] == 0 }

    [decrypted.skip(1000), decrypted.skip(1000), decrypted.skip(1000)]
  end

  def mix_one(num, index)
    _debug("mixing list", decrypted:)
    decrypted.remove({ num:, index: })
    _debug("removed #{num}", decrypted:)
    decrypted.skip(num)
    _debug("skipped #{num}", decrypted:)
    decrypted.insert({ num:, index: })
  end

  def decrypted
    @decrypted ||=
      numbers
        .each_with_index
        .map { |num, index| { num:, index: } }
        .to_linked_list
  end
end
