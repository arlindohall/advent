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
    grove_coordinates.tap { |it| p(it:) }.sum
  end

  def mix!
    numbers.each { |num| mix_one(num) }
  end

  def grove_coordinates
    idx_zero = decrypted.scan(0)

    [decrypted.skip(1000), decrypted.skip(1000), decrypted.skip(1000)]
  end

  def mix_one(num)
    _debug("mixing list", decrypted:)
    decrypted.remove(num)
    _debug("removed #{num}", decrypted:)
    decrypted.skip(num)
    _debug("skipped #{num}", decrypted:)
    decrypted.insert(num)
  end

  def decrypted
    @decrypted ||= numbers.dup.to_linked_list
  end
end
