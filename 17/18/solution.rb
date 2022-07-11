
Instruction = Struct.new(:op, :target, :source)

class Duet
  def initialize(instructions)
    @instructions = instructions
  end

  def self.of(text)
    new(
      text.strip.lines.map{|l| parse(l)}
    )
  end

  def execute
    @pc, @reg, @received, @sent = 0, {}, [], []
    until done?
      interpret
    end

    [@received.first]
  end

  def done?
    @received.any?
  end

  <<-docs
  snd X plays a sound with a frequency equal to the value of X.
  set X Y sets register X to the value of Y.
  add X Y increases register X by the value of Y.
  mul X Y sets register X to the result of multiplying the value contained in register X by the value of Y.
  mod X Y sets register X to the remainder of dividing the value contained in register X by the value of Y (that is, it sets X to the result of X modulo Y).
  rcv X recovers the frequency of the last sound played, but only when the value of X is not zero. (If it is zero, the command does nothing.)
  jgz X Y jumps with an offset of the value of Y, but only if the value of X is greater than zero. (An offset of 2 skips the next instruction, an offset of -1 jumps to the previous instruction, and so on.)
  docs
  def interpret
    case current.op
    when :jgz
      if value_of(current.target) > 0
        @pc += value_of(current.source)
        return # do not increment program counter again
      end
    when :snd
      @sent << value_of(current.target)
    when :set
      set(current.target, value_of(current.source))
    when :add
      set(current.target, value_of(current.target) + value_of(current.source))
    when :mul
      set(current.target, value_of(current.target) * value_of(current.source))
    when :mod
      set(current.target, value_of(current.target) % value_of(current.source))
    when :rcv
      if value_of(current.target) != 0
        @received << @sent.last
      end
    end

    @pc += 1
  end

  def current
    @instructions[@pc]
  end

  def value_of(val)
    if val.nil?
      pp self
      raise "Nil value"
    end

    if val.include?(:number)
      val[:number]
    elsif val.include?(:register)
      @reg[val[:register]] ||= 0
    else
      raise "Unknown value: #{val}"
    end
  end

  def set(reg, val)
    @reg[reg[:register]] = val
  end

  def self.parse(instruction)
    op, first, second = instruction.split
    target, source = [first, second].map{|v| register_or_value(v)}
    op = op.to_sym
    Instruction.new(op, target, source)
  end

  def self.register_or_value(value)
    return nil if value.nil?

    case value
    when /\d+/
      { number: value.to_i }
    when /\w/
      { register: value.to_sym }
    else
      raise "Unknown value or register: #{value}"
    end
  end
end

@example = <<-inst
set a 1
add a 2
mul a a
mod a 5
snd a
set a 0
rcv a
jgz a -1
set a 1
jgz a -2
inst

@input = <<-inst
set i 31
set a 1
mul p 17
jgz p p
mul a 2
add i -1
jgz i -2
add a -1
set i 127
set p 316
mul p 8505
mod p a
mul p 129749
add p 12345
mod p a
set b p
mod b 10000
snd b
add i -1
jgz i -9
jgz a 3
rcv b
jgz b -1
set f 0
set i 126
rcv a
rcv b
set p a
mul p -1
add p b
jgz p 4
snd a
set a b
jgz 1 3
snd b
set f 1
add i -1
jgz i -11
snd a
jgz f -16
jgz a -19
inst