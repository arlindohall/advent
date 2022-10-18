
class FFT
  attr_reader :input

  def initialize(input, size = nil)
    @input = input
    @size = size || input.size
  end

  def self.parse(input)
    new(input.chars.map(&:to_i))
  end

  def real_signal
    FFT.new(@input, @size * 10000)
  end

  def first_eight
    output(100).take(8).map(&:to_s).join
  end

  def first_eight_with_offset
    @offset = true
    first_eight
  end

  def output(n)
    result = self
    n.times { |i| result = result.next_phase; puts "step #{i}" }
    result.input
  end

  def next_phase
    FFT.new(
      @size.times.map do |i|
        digit(i)
      end,
      @size
    )
  end

  def digit(i)
    sum = 0
    pattern(i+1) do |idx, mult|
      sum += @input[idx % @input.size] * mult
    end
    sum.abs.modulo(10)
  end

  def pattern(bit)
    shift, index = 1, 0             unless @offset
    shift, index = first_seven, 0   if @offset
    until index >= @size
      yield(index, mult_for(shift, bit))
      index += 1 ; shift += 1
    end
  end

  def first_seven
    @input.take(7).map(&:to_s).join.to_i
  end

  def mult_for(index, bit)
    case (index / (bit)) % 4
    when 0 ; 0
    when 1 ; 1
    when 2 ; 0
    when 3 ; -1
    else raise "WTF I divided by four"
    end
  end
end

def assert(expected)
  result = @test.next_phase
  raise "Expected #{expected} but got #{result.input}" unless result.input == expected.chars.map(&:to_i)
  @test = result
end

def test
  @test = FFT.parse("12345678")
  assert("48226158")
  assert("34040438")
  assert("03415518")
  assert("01029498")

  raise unless FFT.parse("80871224585914546619083218645595").first_eight == "24176176"
  raise unless FFT.parse("19617804207202209144916044189917").first_eight == "73745418"
  raise unless FFT.parse("69317163492948606335995924319873").first_eight == "52432133"

  raise unless FFT.parse("03036732577212944063491565474664").real_signal.first_eight_with_offset == "84462026"
  raise unless FFT.parse("02935109699940807407585447034323").real_signal.first_eight_with_offset == "78725270"
  raise unless FFT.parse("03081770884921959731165446850517").real_signal.first_eight_with_offset == "53553731"

  :success
end

def solve
  [
    FFT.parse(@input).first_eight,
    # FFT.parse(@input).real_signal.first_eight_with_offset,
  ]
end

@input = "59756772370948995765943195844952640015210703313486295362653878290009098923609769261473534009395188480864325959786470084762607666312503091505466258796062230652769633818282653497853018108281567627899722548602257463608530331299936274116326038606007040084159138769832784921878333830514041948066594667152593945159170816779820264758715101494739244533095696039336070510975612190417391067896410262310835830006544632083421447385542256916141256383813360662952845638955872442636455511906111157861890394133454959320174572270568292972621253460895625862616228998147301670850340831993043617316938748361984714845874270986989103792418940945322846146634931990046966552"
@example = FFT.new("12345678")