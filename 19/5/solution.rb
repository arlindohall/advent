
class Object
  def plop
    p self
  end
end

class IntcodeProgram
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

  def solve
    [
      dup.prep_input(1).interpret.last,
      dup.prep_input(5).interpret.last,
    ]
  end

  def prep_input(input)
    @outputs = []
    @inputs = [input]
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

def solve
  IntcodeProgram.parse(@input).solve
end

@input = <<-input
3,225,1,225,6,6,1100,1,238,225,104,0,1002,188,27,224,1001,224,-2241,224,4,224,102,8,223,223,1001,224,6,224,1,223,224,223,101,65,153,224,101,-108,224,224,4,224,1002,223,8,223,1001,224,1,224,1,224,223,223,1,158,191,224,101,-113,224,224,4,224,102,8,223,223,1001,224,7,224,1,223,224,223,1001,195,14,224,1001,224,-81,224,4,224,1002,223,8,223,101,3,224,224,1,224,223,223,1102,47,76,225,1102,35,69,224,101,-2415,224,224,4,224,102,8,223,223,101,2,224,224,1,224,223,223,1101,32,38,224,101,-70,224,224,4,224,102,8,223,223,101,3,224,224,1,224,223,223,1102,66,13,225,1102,43,84,225,1101,12,62,225,1102,30,35,225,2,149,101,224,101,-3102,224,224,4,224,102,8,223,223,101,4,224,224,1,223,224,223,1101,76,83,225,1102,51,51,225,1102,67,75,225,102,42,162,224,101,-1470,224,224,4,224,102,8,223,223,101,1,224,224,1,223,224,223,4,223,99,0,0,0,677,0,0,0,0,0,0,0,0,0,0,0,1105,0,99999,1105,227,247,1105,1,99999,1005,227,99999,1005,0,256,1105,1,99999,1106,227,99999,1106,0,265,1105,1,99999,1006,0,99999,1006,227,274,1105,1,99999,1105,1,280,1105,1,99999,1,225,225,225,1101,294,0,0,105,1,0,1105,1,99999,1106,0,300,1105,1,99999,1,225,225,225,1101,314,0,0,106,0,0,1105,1,99999,1108,226,677,224,1002,223,2,223,1005,224,329,101,1,223,223,108,226,226,224,1002,223,2,223,1005,224,344,1001,223,1,223,1107,677,226,224,1002,223,2,223,1006,224,359,101,1,223,223,1008,226,226,224,1002,223,2,223,1005,224,374,101,1,223,223,8,226,677,224,102,2,223,223,1006,224,389,101,1,223,223,7,226,677,224,1002,223,2,223,1005,224,404,1001,223,1,223,7,226,226,224,1002,223,2,223,1005,224,419,101,1,223,223,107,226,677,224,1002,223,2,223,1005,224,434,101,1,223,223,107,226,226,224,1002,223,2,223,1005,224,449,1001,223,1,223,1107,226,677,224,102,2,223,223,1006,224,464,1001,223,1,223,1007,677,226,224,1002,223,2,223,1006,224,479,1001,223,1,223,1107,677,677,224,1002,223,2,223,1005,224,494,101,1,223,223,1108,677,226,224,102,2,223,223,1006,224,509,101,1,223,223,7,677,226,224,1002,223,2,223,1005,224,524,1001,223,1,223,1008,677,226,224,102,2,223,223,1005,224,539,1001,223,1,223,1108,226,226,224,102,2,223,223,1005,224,554,101,1,223,223,107,677,677,224,102,2,223,223,1006,224,569,1001,223,1,223,1007,226,226,224,102,2,223,223,1006,224,584,101,1,223,223,8,677,677,224,102,2,223,223,1005,224,599,1001,223,1,223,108,677,677,224,1002,223,2,223,1005,224,614,101,1,223,223,108,226,677,224,102,2,223,223,1005,224,629,101,1,223,223,8,677,226,224,102,2,223,223,1006,224,644,1001,223,1,223,1007,677,677,224,1002,223,2,223,1006,224,659,1001,223,1,223,1008,677,677,224,1002,223,2,223,1005,224,674,101,1,223,223,4,223,99,226
input