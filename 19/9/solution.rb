
###########################################################
######################### INTCODE #########################
###########################################################

class Object
  def plop
    p self
  end
end

class IntcodeProgram
  attr_reader :text

  OPCODES = {
    1 =>            :add,
    2 =>            :multiply,
    3 =>            :read_value,
    4 =>            :write_value,
    5 =>            :jump_if_true,
    6 =>            :jump_if_false,
    7 =>            :less_than,
    8 =>            :equals,
    9 =>            :adjust_relative_base,
    99 =>           :halt,
  }

  SIZE = {
    multiply:               4,
    add:                    4,
    read_value:             2,
    write_value:            2,
    jump_if_true:           0,
    jump_if_false:          0,
    less_than:              4,
    equals:                 4,
    adjust_relative_base:   2,
    halt:                   0,
  }

  def initialize(text)
    @text = text
  end

  def dup
    IntcodeProgram.new(@text.dup)
  end

  def prep_input(inputs)
    @inputs = inputs.reverse
    @outputs = []
    self
  end

  def initialize_input
    @inputs ||= []
    @outputs ||= []
  end

  def interpret
    initialize_input
    @ip, @rb = 0, 0

    until done?
      step
    end

    @outputs
  end

  def done?
    @ip >= @text.length
  end

  def step
    perform_opcode
  end

  def perform_opcode
    code = OPCODES[current]
    # debug(code)

    raise "Unknown opcode #{@ip}, #{current}" unless code
    send(code)
    @ip += SIZE[code]
  end

  def debug(code)
    [
      'code=>', code,
      'ip=>', @ip,
      'rb=>', @rb,
      'text=>', @text[@ip..@ip + SIZE[code] - 1],
      'modes=>', modes(SIZE[code] > 2 ? SIZE[code] - 2 : 0),
      'outputs=>', @outputs,
    ].plop
    @text.plop
    puts
  end

  def halt
    @ip = @text.length
  end

  def multiply
    @text[target(3)] = parameters(2).reduce(&:*)
  end

  def add
    @text[target(3)] = parameters(2).sum
  end

  def read_value
    raise "Missing input" if @inputs.empty?
    @text[target(1)] = @inputs.pop.to_i
  end

  def write_value
    @outputs << parameters(1).first
  end

  def jump_if_true
    first, second = parameters(2)
    if first != 0
      @ip = second
    else
      # Increment by size, because we record size as zero above
      @ip += 3
    end
  end

  def jump_if_false
    first, second = parameters(2)
    if first == 0
      @ip = second
    else
      # Increment by size, because we record size as zero above
      @ip += 3
    end
  end

  def less_than
    first, second = parameters(2)
    @text[target(3)] = first < second ? 1 : 0
  end

  def equals
    first, second = parameters(2)
    @text[target(3)] = first == second ? 1 : 0
  end

  def adjust_relative_base
    # todo: broken
    param = parameters(1).first
    @rb += param
  end

  def parameters(count)
    @text[@ip+1..@ip+count]
      .zip(modes(count))
      .map { |value, mode| parameter(value, mode) }
  end

  def parameter(value, mode)
    case mode
    when 0
      position(value)
    when 1
      immediate(value)
    when 2
      relative(value)
    end
  end

  def immediate(value)
    value
  end

  def position(value)
    raise "negative reference" if value < 0
    if value > @text.length
      @text.size.upto(value) { @text << 0 }
      @text[value]
    else
      @text[value]
    end
  end

  def relative(value)
    value = @rb + value
    raise "negative reference" if value < 0
    if value > @text.length
      @text.size.upto(value) { @text << 0 }
      @text[value]
    else
      @text[value]
    end
  end

  def target(count)
    case modes(count).last
    when 0
      @text[@ip + count]
    when 1
      raise "cannot write to immediate value"
    when 2
      @rb + @text[@ip + count]
    end
  end

  def modes(count)
    1.upto(count).map { |shift|
      (@text[@ip] / (10 ** (shift + 1))) % 10
    }
  end

  def current
    @text[@ip] % 100
  end

  class << self
    def parse(text)
      new(text.split(",").map(&:to_i).freeze)
    end
  end
end

def test
  raise 'large'   unless IntcodeProgram.parse(@large_number).dup.interpret.first ==
    1125899906842624
  raise 'sixteen' unless IntcodeProgram.parse(@sixteen_digit).dup.interpret.first.to_s.chars.count ==
    16
  raise 'quine'   unless IntcodeProgram.parse(@quine).dup.interpret ==
    [109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99]
end

def solve
  [
    IntcodeProgram.parse(@input).dup.prep_input([1]).interpret.last,
    IntcodeProgram.parse(@input).dup.prep_input([2]).interpret.first,
  ]
end

@quine = "109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99"
@sixteen_digit = "1102,34915192,34915192,7,4,7,99,0"
@large_number = "104,1125899906842624,99"

@input = <<-input.strip
1102,34463338,34463338,63,1007,63,34463338,63,1005,63,53,1102,1,3,1000,109,988,209,12,9,1000,209,6,209,3,203,0,1008,1000,1,63,1005,63,65,1008,1000,2,63,1005,63,904,1008,1000,0,63,1005,63,58,4,25,104,0,99,4,0,104,0,99,4,17,104,0,99,0,0,1101,0,0,1020,1102,1,800,1023,1101,0,388,1025,1101,0,31,1012,1102,1,1,1021,1101,22,0,1014,1101,0,30,1002,1101,0,716,1027,1102,32,1,1009,1101,0,38,1017,1102,20,1,1015,1101,33,0,1016,1101,0,35,1007,1101,0,25,1005,1102,28,1,1011,1102,1,36,1008,1101,0,39,1001,1102,1,21,1006,1101,397,0,1024,1102,1,807,1022,1101,0,348,1029,1101,0,23,1003,1101,29,0,1004,1102,1,26,1013,1102,34,1,1018,1102,1,37,1010,1101,0,27,1019,1102,24,1,1000,1101,353,0,1028,1101,0,723,1026,109,14,2101,0,-9,63,1008,63,27,63,1005,63,205,1001,64,1,64,1106,0,207,4,187,1002,64,2,64,109,-17,2108,24,6,63,1005,63,223,1105,1,229,4,213,1001,64,1,64,1002,64,2,64,109,7,2101,0,2,63,1008,63,21,63,1005,63,255,4,235,1001,64,1,64,1106,0,255,1002,64,2,64,109,-7,2108,29,7,63,1005,63,273,4,261,1106,0,277,1001,64,1,64,1002,64,2,64,109,10,1208,-5,31,63,1005,63,293,1105,1,299,4,283,1001,64,1,64,1002,64,2,64,109,2,1207,-1,35,63,1005,63,315,1106,0,321,4,305,1001,64,1,64,1002,64,2,64,109,8,1205,3,333,1106,0,339,4,327,1001,64,1,64,1002,64,2,64,109,11,2106,0,0,4,345,1106,0,357,1001,64,1,64,1002,64,2,64,109,-15,21108,40,40,6,1005,1019,379,4,363,1001,64,1,64,1106,0,379,1002,64,2,64,109,16,2105,1,-5,4,385,1001,64,1,64,1105,1,397,1002,64,2,64,109,-25,2102,1,-1,63,1008,63,26,63,1005,63,421,1001,64,1,64,1106,0,423,4,403,1002,64,2,64,109,-8,1202,9,1,63,1008,63,25,63,1005,63,445,4,429,1105,1,449,1001,64,1,64,1002,64,2,64,109,5,1207,0,40,63,1005,63,467,4,455,1106,0,471,1001,64,1,64,1002,64,2,64,109,-6,2107,24,8,63,1005,63,487,1105,1,493,4,477,1001,64,1,64,1002,64,2,64,109,15,21107,41,40,1,1005,1011,509,1106,0,515,4,499,1001,64,1,64,1002,64,2,64,109,12,1205,-1,529,4,521,1105,1,533,1001,64,1,64,1002,64,2,64,109,-20,2102,1,2,63,1008,63,29,63,1005,63,555,4,539,1105,1,559,1001,64,1,64,1002,64,2,64,109,15,1201,-9,0,63,1008,63,38,63,1005,63,579,1105,1,585,4,565,1001,64,1,64,1002,64,2,64,109,-2,21102,42,1,-3,1008,1012,44,63,1005,63,609,1001,64,1,64,1106,0,611,4,591,1002,64,2,64,109,-21,2107,29,8,63,1005,63,629,4,617,1106,0,633,1001,64,1,64,1002,64,2,64,109,15,1202,0,1,63,1008,63,30,63,1005,63,657,1001,64,1,64,1106,0,659,4,639,1002,64,2,64,109,15,21102,43,1,-8,1008,1016,43,63,1005,63,681,4,665,1105,1,685,1001,64,1,64,1002,64,2,64,109,-10,21107,44,45,-4,1005,1010,707,4,691,1001,64,1,64,1106,0,707,1002,64,2,64,109,11,2106,0,2,1001,64,1,64,1106,0,725,4,713,1002,64,2,64,109,-16,21101,45,0,8,1008,1017,43,63,1005,63,749,1001,64,1,64,1105,1,751,4,731,1002,64,2,64,109,-3,1208,2,36,63,1005,63,773,4,757,1001,64,1,64,1106,0,773,1002,64,2,64,109,18,1206,-4,787,4,779,1105,1,791,1001,64,1,64,1002,64,2,64,109,-8,2105,1,7,1001,64,1,64,1106,0,809,4,797,1002,64,2,64,109,-2,21108,46,44,2,1005,1016,825,1105,1,831,4,815,1001,64,1,64,1002,64,2,64,109,7,21101,47,0,-8,1008,1013,47,63,1005,63,857,4,837,1001,64,1,64,1105,1,857,1002,64,2,64,109,-17,1201,-4,0,63,1008,63,24,63,1005,63,883,4,863,1001,64,1,64,1105,1,883,1002,64,2,64,109,10,1206,7,895,1106,0,901,4,889,1001,64,1,64,4,64,99,21102,1,27,1,21102,1,915,0,1105,1,922,21201,1,24405,1,204,1,99,109,3,1207,-2,3,63,1005,63,964,21201,-2,-1,1,21101,942,0,0,1106,0,922,22102,1,1,-1,21201,-2,-3,1,21101,0,957,0,1106,0,922,22201,1,-1,-2,1106,0,968,21201,-2,0,-2,109,-3,2106,0,0
input