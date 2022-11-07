
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
    @inputs = []
    @outputs = []
  end

  def dup
    IntcodeProgram.new(@text.dup)
  end

  def prep_channels!(inputs = [], outputs = [])
    @inputs = inputs
    @outputs = outputs
    self
  end

  def interpret!
    @state ||= :running # leave state alone so we can call recursively
    @ip, @rb = 0, 0

    loop do
      until done? || paused?
        step!
      end

      return @outputs if done?

      raise 'running through, cannot read' if reading?

      adjust_ip!
      @state = :running
    end
  end

  def start!
    @state = :running
    @ip, @rb = 0, 0

    until done? || paused?
      step!
    end

    @outputs if done?
  end

  def continue!
    adjust_ip!

    @state = :running

    until done? || paused?
      step!
    end

    @outputs if done?
  end

  def adjust_ip!
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

  def not_started?
    @state.nil?
  end

  def step!
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
    print "\033[H"
    @text.map{ |ch| print ch.to_s.rjust(5) }
    puts
    [
      'code=>', code,
      'ip=>', @ip,
      'rb=>', @rb,
      'text=>', @text[@ip..@ip + SIZE[code] - 1],
      'modes=>', modes(SIZE[code] > 2 ? SIZE[code] - 2 : 0),
      'outputs=>', @outputs,
    ].each { |s| print s.to_s.ljust(25) }
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
    return pause(:reading) if @inputs.empty?
    @text[target(1)] = @inputs.shift.to_i
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

  def adjust_relative_base
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
      position(value) || 0
    when 1
      immediate(value) || 0
    when 2
      relative(value) || 0
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

  def override!(position, value)
    @text[position] = value
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