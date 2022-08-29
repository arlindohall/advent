
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
    99 =>           :halt,
  }

  SIZE = {
    multiply:       4,
    add:            4,
    read_value:     2,
    write_value:    2,
    jump_if_true:   0,
    jump_if_false:  0,
    less_than:      4,
    equals:         4,
    halt:           0,
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

  def interpret
    @ip = 0

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
    # [
    #   code,
    #   @ip,
    #   @text[@ip..@ip + SIZE[code] - 1],
    #   modes(SIZE[code] > 2 ? SIZE[code] - 2 : 0),
    # ].plop
    # @outputs.plop

    raise "Unknown opcode #{@ip}, #{current}" unless code
    send(code)
    @ip += SIZE[code]
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
    @text[@text[@ip+1]] = @inputs.pop.to_i
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

  def parameters(count)
    @text[@ip+1..@ip+count]
      .zip(modes(count))
      .map { |value, mode| mode == 0 ? @text[value] : value }
  end

  def target(count)
    @text[@ip+count]
  end

  def modes(count)
    1.upto(count).map { |shift|
      (@text[@ip] / (10 ** (shift + 1))) % 10
    }
  end

  def current
    @text[@ip] % 100
  end

  def inspect
    "#<IntcodeProgram @ip=#{@ip} @text.size=#{@text.size}>"
  end

  class << self
    def parse(text)
      new(text.split(",").map(&:to_i).freeze)
    end
  end
end

############################################################## 
######################### AMPLIFIERS ######################### 
############################################################## 

class AmplifierRelay
  attr_reader :program

  def initialize(program)
    @program = program
  end

  def solve
    phase_settings.map { |phases| output_of(phases) }.max
  end

  def output_of(phases)
    output = 0
    phases.each { |ph| output = run(output, ph)}
    output
  end
  
  def run(input, phase)
    @program.dup.prep_input([phase, input]).interpret.last
  end

  def phase_settings
    [0,1,2,3,4].permutation
  end

  class << self
    def parse(text)
      new(IntcodeProgram.parse(text))
    end
  end
end

@example1 = "3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0"
@answer1 = 43210
@example2 = "3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0"
@answer2 = 54321
@example3 = "3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0"
@answer3 = 65210

@input = "3,8,1001,8,10,8,105,1,0,0,21,42,67,88,101,114,195,276,357,438,99999,3,9,101,3,9,9,1002,9,4,9,1001,9,5,9,102,4,9,9,4,9,99,3,9,1001,9,3,9,1002,9,2,9,101,2,9,9,102,2,9,9,1001,9,5,9,4,9,99,3,9,102,4,9,9,1001,9,3,9,102,4,9,9,101,4,9,9,4,9,99,3,9,101,2,9,9,1002,9,3,9,4,9,99,3,9,101,4,9,9,1002,9,5,9,4,9,99,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,99,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,99,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,102,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,1001,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,101,2,9,9,4,9,99"