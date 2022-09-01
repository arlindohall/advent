
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
    @inputs = []
    @outputs = []
  end

  def dup
    IntcodeProgram.new(@text.dup)
  end

  def prep_channels(inputs, outputs)
    @inputs = inputs
    @outputs = outputs
    self
  end

  def start
    @state = :running
    @ip = 0

    until done? || paused?
      step
    end

    @outputs if done?
  end

  def continue
    adjust_ip

    @state = :running

    until done? || paused?
      step
    end

    @outputs if done?
  end

  def adjust_ip
    case @state
    when :running
      raise "program was not paused"
    when :writing
      nil # pass because we already incremented the instruction pointer
    when :reading
      @ip -= SIZE[:read_value]
    end
  end

  def done?
    @ip >= @text.length
  end

  def running?
    @state == :running
  end

  def paused?
    reading? || writing?
  end

  def reading?
    @state == :reading
  end

  def writing?
    @state == :writing
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
    # [@inputs, @outputs].plop

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
    return pause(:reading) if @inputs.empty?
    @text[@text[@ip+1]] = @inputs.shift.to_i
  end

  def write_value
    @outputs << parameters(1).first
    pause(:writing)
  end

  def pause(reason = :reading)
    @state = reason
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

  def send_signal(val)
    @inputs << val
  end

  def receive_signals
    op = @outputs
    @outputs = []
    op
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
    # require 'pry-nav' ; require 'pry' ; binding.pry
    @amplifiers = phases.map { @program.dup }

    input_to_amplifiers(phases)
    @amplifiers.each(&:start)

    @amplifiers.first.send_signal(0)
    @amplifiers.first.continue

    @index = 0
    @outputs = []
    until @amplifiers.last.done?
      raise "exited early at amp=#{@index}" if current.done?
      # current.plop
      current.continue
      current.receive_signals.each { |signal|
        @outputs << signal if @index == 4
        next_amp.send_signal(signal)
      }
      advance
    end

    @outputs.plop
    @outputs.last
  end
  
  def input_to_amplifiers(input)
    @amplifiers.zip(input)
      .each { |amp, phase| amp.prep_channels([phase], []) }
  end

  def phase_settings
    [5,6,7,8,9].permutation
  end

  def current
    @amplifiers[@index]
  end

  def next_amp
    @amplifiers[(@index+1)%5]
  end

  def advance
    @index += 1
    @index %= 5
  end

  class << self
    def parse(text)
      new(IntcodeProgram.parse(text))
    end
  end
end

@example1 = "3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5"
@answer1 = 139629729
@example2 = "3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,-5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10"
@answer2 = 18216

@input = "3,8,1001,8,10,8,105,1,0,0,21,42,67,88,101,114,195,276,357,438,99999,3,9,101,3,9,9,1002,9,4,9,1001,9,5,9,102,4,9,9,4,9,99,3,9,1001,9,3,9,1002,9,2,9,101,2,9,9,102,2,9,9,1001,9,5,9,4,9,99,3,9,102,4,9,9,1001,9,3,9,102,4,9,9,101,4,9,9,4,9,99,3,9,101,2,9,9,1002,9,3,9,4,9,99,3,9,101,4,9,9,1002,9,5,9,4,9,99,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,99,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,99,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,102,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,1001,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,101,2,9,9,4,9,99"