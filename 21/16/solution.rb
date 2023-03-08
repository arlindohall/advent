def solve = BitString.parse(read_input).then { |it| [it.versions, it.evaluate] }

class BitString
  attr_reader :binary
  def initialize(binary)
    @binary = binary
  end

  def versions
    outermost.version_sum
  end

  def evaluate
    outermost.evaluate
  end

  # Always one outermost packet
  memoize def outermost
    read_packet
  end

  # Used by sub-packets
  memoize def packets
    @index = 0
    packets = []
    packets << read_packet until index > max_start_of_packet
    packets
  end

  attr_reader :start, :index
  def read_packet
    @start = @index ||= 0

    v = read_version
    t = read_type

    if t == 4
      read_literal(v, t)
    else
      read_operator(v, t)
    end
  end

  def read_literal(version, type)
    bytes = []
    bytes << read_nibble until current.zero?
    bytes << read_nibble # the last one starts with zero

    Literal.new(version, type, bytes.join.to_i(2), bytes)
  end

  def read_operator(version, type)
    case advance.to_i(2) # length_type
    when 0
      read_operator_bits(version, type, advance(15).to_i(2))
    when 1
      read_operator_packets(version, type, advance(11).to_i(2))
    else
      raise "Unreachable"
    end
  end

  def read_operator_bits(version, type, bits)
    sub_packets = BitString.new(advance(bits))
    Operator.new(version, type, sub_packets.packets)
  end

  def read_operator_packets(version, type, packets)
    op = Operator.new(version, type, [])

    op.sub_packets << read_packet until op.sub_packets.size >= packets

    raise "Too many packets read" if op.sub_packets.size > packets

    op
  end

  def read_version
    advance(3).to_i(2)
  end

  def read_type
    advance(3).to_i(2)
  end

  def read_nibble
    raise "EOS" if index >= binary.size
    advance
    advance(4)
  end

  def current
    binary[@index].to_i(2)
  end

  def advance(n = 1)
    @index += n
    binary[@index - n...@index]
  end

  def max_start_of_packet
    binary.size - 11
  end

  def self.parse(input)
    new(
      input
        .chars
        .map { |ch| ch.to_i(16) }
        .map { |i| i.to_s(2).rjust(4, "0") }
        .join
    )
  end

  class Literal
    attr_reader :version, :type, :number, :bytes
    def initialize(version, type, number, bytes)
      @version = version
      @type = type
      @number = number
      @bytes = bytes
    end

    def evaluate
      number
    end

    def sub_packets = []

    def sub_packet_count = 1

    def version_sum
      version
    end
  end

  class Operator
    attr_reader :version, :type, :sub_packets
    def initialize(version, type, sub_packets)
      @version = version
      @type = type
      @sub_packets = sub_packets
    end

    memoize def values
      sub_packets.map(&:evaluate)
    end

    def evaluate
      case type
      when 0
        values.sum
      when 1
        values.product
      when 2
        values.min
      when 3
        values.max
      when 5
        values.first > values.second ? 1 : 0
      when 6
        values.first < values.second ? 1 : 0
      when 7
        values.first == values.second ? 1 : 0
      else
        raise "Unreachable"
      end
    end

    def sub_packet_count
      1 + sub_packets.map(&:sub_packet_count).sum
    end

    def version_sum
      version + sub_packets.map(&:version_sum).sum
    end
  end
end

def test
  [
    [6, "D2FE28"],
    [9, "38006F45291200"],
    [14, "EE00D40C823060"],
    [16, "8A004A801A8002F478"],
    [12, "620080001611562C8802118E34"],
    [23, "C0015000016115A2E0802F182340"],
    [31, "A0016C880162017C3686B18A3D4780"]
  ].each do |expected, input|
    result = BitString.parse(input).versions
    raise({ input:, result:, expected: }.to_s) unless result == expected
  end

  [
    [3, "C200B40A82"],
    [54, "04005AC33890"],
    [7, "880086C3E88112"],
    [9, "CE00C43D881120"],
    [1, "D8005AC2A8F0"],
    [0, "F600BC2D8F"],
    [0, "9C005AC2F8F0"],
    [1, "9C0141080250320F1802104A08"]
  ].each do |expected, input|
    result = BitString.parse(input).evaluate
    raise({ input:, result:, expected: }.to_s) unless result == expected
  end

  raise "Broken for input" unless solve == [953, 246_225_449_979]

  :success
end
