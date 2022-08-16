
module IntcodeDebugger
  def debug
    @scanner = 0
    @section = :text
    until @scanner >= @text.size
      puts current_set.join(',') + ','
      increment_scanner
    end

    puts
  end

  def current_set
    if @section == :text && @text[@scanner] != 99
      @text[@scanner..@scanner+3]
    elsif @section == :text && @text[@scanner] == 99
      @text[@scanner..@scanner]
    elsif @section == :data
      @text[@scanner..]
    elsif @section == :text
      raise "Invalid opcode #{@text[@scanner]}"
    else
      raise "Invalid section #{@section}"
    end
  end

  def increment_scanner
    if @section == :text && @text[@scanner] != 99
      @scanner += 4
    elsif @section == :text && @text[@scanner] == 99
      @scanner += 1
    elsif @section == :data
      @scanner = @text.size
    elsif @section == :text
      raise "Invalid opcode #{@text[@scanner]}"
    else
      raise "Invalid section #{@section}"
    end
  end
end

class IntcodeProgram
  include IntcodeDebugger

  def initialize(text)
    @text = text
  end

  def prep(noun = 12, verb = 2)
    text = @text.dup

    text[1] = noun
    text[2] = verb

    self.class.new(text)
  end

  def find_inputs
    @noun, @verb = 0, 0

    until found_inputs?
      increment_inputs
    end

    @noun * 100 + @verb
  end

  def found_inputs?
    # Check flipped because we never increment @verb more than @noun
    @verb, @noun = @noun, @verb
    return true if prep(@noun, @verb).interpret.first == 19690720

    @verb, @noun = @noun, @verb
    prep(@noun, @verb).interpret.first.tap { |x| puts x } == 19690720
  rescue TypeError
    # Failure due to overrun I think
    false
  end

  def increment_inputs
    p [@noun, @verb] if @verb == 0 && @noun % 100 == 0

    if @verb >= @noun
      @noun += 1
      @verb = 0
    else
      @verb += 1
    end
  end

  def interpret
    @ip = 0
    # debug

    until done?
      step
    end

    # debug
    @text
  end

  def done?
    @ip >= @text.length
  end

  def step
    perform_opcode
    increment_ip
  end

  def perform_opcode
    case current
    when 1
      set_result(operands.sum)
    when 2
      set_result(operands.reduce(&:*))
    when 99
      @ip = @text.length
    else
      raise "Invalid opcode #{@ip}, #{@current}"
    end
  end

  def set_result(value)
    @text[target] = value
  end

  def operands
    @text[@ip + 1..@ip + 2]
      .map { |i| @text[i] }
  end

  def target
    @text[@ip + 3]
  end

  def current
    @text[@ip]
  end

  def increment_ip
    @ip += 4
  end

  class << self
    def parse(text)
      new(text.split(",").map(&:to_i).freeze)
    end
  end
end

@example1 = "1,9,10,3,2,3,11,0,99,30,40,50"
@example2 = "1,0,0,0,99"
@example3 = "2,3,0,3,99"
@example4 = "2,4,4,5,99,0"
@example5 = "1,1,1,4,99,5,6,0,99"

def test
  [
    [@example1, [3500,9,10,70,2,3,11,0,99,30,40,50]],
    [@example2, [2,0,0,0,99]],
    [@example3, [2,3,0,6,99]],
    [@example4, [2,4,4,5,99,9801]],
    [@example5, [30,1,1,4,2,5,6,0,99]],
  ].each { |program, state|
    ip = IntcodeProgram.parse(program)
    raise "FAIL" unless ip.interpret == state
    ip.debug
  }

  puts "PASS"
end

@input = <<-input.strip
1,0,0,3,1,1,2,3,1,3,4,3,1,5,0,3,2,9,1,19,1,19,6,23,2,6,23,27,2,27,9,31,1,5,31,35,1,35,10,39,2,39,9,43,1,5,43,47,2,47,10,51,1,51,6,55,1,5,55,59,2,6,59,63,2,63,6,67,1,5,67,71,1,71,9,75,2,75,10,79,1,79,5,83,1,10,83,87,1,5,87,91,2,13,91,95,1,95,10,99,2,99,13,103,1,103,5,107,1,107,13,111,2,111,9,115,1,6,115,119,2,119,6,123,1,123,6,127,1,127,9,131,1,6,131,135,1,135,2,139,1,139,10,0,99,2,0,14,0
input

def solve
  program = IntcodeProgram.parse(@input)
  [program.prep.interpret[0], program.find_inputs]
end