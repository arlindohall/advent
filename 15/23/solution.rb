
require 'pry'

Machine = Struct.new(:a, :b, :pc, :program)

class Machine
  def value(register)
    send("#{register}")
  end

  def set(register, value)
    send("#{register}=", value)
  end

  def finished?
    pc < 0 || pc >= program.length
  end

  def step
    instruction = program[self.pc]
    puts "pc: #{pc}, a: #{a}, b: #{b}, program: #{instruction}"

    instruction.perform(self)
    self.pc += 1 unless JumpInstruction === instruction
  end

  def run
    while !finished?
      step
    end
  end
end

Instruction ||= Struct.new(:source)
class Instruction
  def perform(machine)
    raise NotImplementedError
  end
end

class RegisterInstruction < Instruction
  def parse
    @register = source.split.last
  end

  def perform(machine)
    machine.set(@register, op(machine.value(@register)))
  end
end

class Hlf < RegisterInstruction
  def op(value)
    value / 2
  end
end

class Tpl < RegisterInstruction
  def op(value)
    value * 3
  end
end

class Inc < RegisterInstruction
  def op(value)
    value + 1
  end
end

class JumpInstruction < Instruction
  def parse
    @offset = source.split(' ').last.to_i
    return if source.split(' ').first == "jmp"

    # Parse condition register
    @condition = source.split(/,? /)[1]
  end

  def perform(machine)
    if condition(machine)
      machine.pc = machine.pc + @offset
    else
      machine.pc += 1
    end
  end
end

class Jmp < JumpInstruction
  def condition(_)
    true
  end
end

class Jie < JumpInstruction
  def condition(machine)
    machine.value(@condition) % 2 == 0
  end
end

class Jio < JumpInstruction
  def condition(machine)
    machine.value(@condition) == 1
  end
end

Input = Struct.new(:text)
class Input
  def read
    @instructions ||= text.strip
      .lines
      .map(&:strip)
      .map{ |line| instruction(line) }
      .map{ |inst| inst.tap(&:parse) }

    Machine.new(0, 0, 0, @instructions)
  end
  
  def instruction(line)
    instruction, _ = line.split(' ')
    case instruction
    when 'hlf'
      Hlf.new(line)
    when 'tpl'
      Tpl.new(line)
    when 'inc'
      Inc.new(line)
    when 'jmp'
      Jmp.new(line)
    when 'jie'
      Jie.new(line)
    when 'jio'
      Jio.new(line)
    else
      raise "Unknown instruction: #{line}"
    end
  end
end

# @machine = Input.new(%Q(
#   inc a
#   jio a, +2
#   tpl a
#   inc a
# )).read

@machine = Input.new(File.read('15/23/input.txt')).read