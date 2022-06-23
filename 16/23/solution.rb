
Cpy = Struct.new(:source, :dest)
Jnz = Struct.new(:source, :distance)
Inc = Struct.new(:register)
Dec = Struct.new(:register)
Tgl = Struct.new(:distance)

Register = Struct.new(:name)
Value = Struct.new(:itself)

MachineState = Struct.new(:pc, :a, :b, :c, :d, :text)

class Computer
  def initialize(instructions)
    @instructions = instructions
      .strip
      .lines
      .map(&:strip)
    @instructions = compile(@instructions)
    @updated = @instructions.clone
  end

  def compile(instructions)
    instructions.map{|i| parse(i)}
  end

  def parse(instruction)
    command, left, right = instruction.split
    case command
    when "cpy"
      copy(left, right)
    when "inc"
      inc(left)
    when "dec"
      dec(left)
    when "jnz"
      jnz(left, right)
    when "tgl"
      tgl(left)
    end
  end

  def run_example
    reset_registers
    while in_bounds?
      execute_current
    end
    # Todo, everywhere machine state is referenced pass an object instead of all variables
    puts "machine_state=#{@machine_state}"
  end

  def run_part1
    reset_registers
    @machine_state.a = 7
    while in_bounds?
      p [@machine_state.values.take(5), current]
      execute_current
    end
    puts "machine_state=#{@machine_state}"
  end

  <<-explanation
  This is taking a very long time to run, but the number in 'a' whenever 'b'
  is decremented is always the number in 'a' last time 'b' was decremented
  times 'b' after 'b' was decremented, so...

  a         b
  12        12 <-- starting value
  12        11
  ...
  132       11 <-- 12 * 11
  132       10
  ...
  1320      10 <-- 132 * 10
  1320      9
  ...
  11880     9 <-- 1320 * 9
  11880     8
  ...

  We can keep this going... it is just computing factorial. When we get to 2 and then
  one, we'll have the factorial, so in this case 12!

  When we ran with 7 as the input though, we got to 5040, or 7!, and then we put 96
  into c and 79 into d, incrementing for each decrement, which is the same as
  adding 96*79 or 7584.

  7584 + 5040 = 12624, which is the answer

  SO we are computing 12! + 7584 = 479009184

  I got this answer when my machine had reached the state...
  [pc=2, a=239500800, b=2, c=-16, d=0], current=#<struct Cpy source=#<struct Register name="a">, dest=#<struct Register name="d">>]
  explanation
  def run_part2
    reset_registers
    @machine_state.a = 12
    instructions_executed = 0
    while in_bounds?
      if @machine_state.d == 0
        p [@machine_state.values.take(5), current]
      end
      instructions_executed += 1
      execute_current
    end
    puts "machine_state=#{@machine_state}"
  end

  def in_bounds?
    @machine_state.pc >= 0 && @machine_state.pc < @updated.size
  end

  def execute_current
    @machine_state = current.execute(@machine_state)
  end

  def current
    @updated[@machine_state.pc]
  end

  def reset_registers
    @updated = @instructions.clone
    @machine_state = MachineState.new(0, 0, 0, 0, 0, @updated)
  end

  def copy(left, right)
    Cpy.new(value_or_register(left), Register.new(right))
  end

  def inc(left)
    Inc.new(Register.new(left))
  end

  def dec(left)
    Dec.new(Register.new(left))
  end

  def jnz(left, right)
    Jnz.new(value_or_register(left), value_or_register(right))
  end

  def tgl(left)
    Tgl.new(value_or_register(left))
  end

  def value_or_register(value)
    case value
    when 'a', 'b', 'c', 'd'
      Register.new(value)
    else
      Value.new(value.to_i)
    end
  end
end

module DoJump
  def do_jump(distance, machine_state)
    pc, a, b, c, d, text = machine_state.values
    if value(machine_state) == 0
      return MachineState.new(pc+1, a, b, c, d, text)
    elsif distance.value(machine_state) == 0
      raise "Impossible jump value zero, pc=#{pc} instruction=#{self}"
      return MachineState.new(pc+1, a, b, c, d, text)
    else
      return MachineState.new(pc+distance.value(machine_state), a, b, c, d, text)
    end
  end
end

class Register
  include DoJump

  def value(machine_state)
    _, a, b, c, d = machine_state.values
    case name
    when 'a'
      a
    when 'b'
      b
    when 'c'
      c
    when 'd'
      d
    end
  end

  def is_value?
    false
  end

  def is_register?
    true
  end
end

class Value
  include DoJump

  def value(machine_state)
    itself
  end

  def is_value?
    true
  end

  def is_register?
    false
  end
end

class Cpy
  def execute(machine_state)
    pc, a, b, c, d, text = machine_state.values

    if dest.is_value?
      return MachineState.new(pc+1, a, b, c, d, text)
    end

    case dest.name
    when 'a'
      return MachineState.new(pc+1, source.value(machine_state), b, c, d, text)
    when 'b'
      return MachineState.new(pc+1, a, source.value(machine_state), c, d, text)
    when 'c'
      return MachineState.new(pc+1, a, b, source.value(machine_state), d, text)
    when 'd'
      return MachineState.new(pc+1, a, b, c, source.value(machine_state), text)
    end
  end

  def toggle
    Jnz.new(source, dest)
  end
end

class Inc
  def execute(machine_state)
    pc, a, b, c, d, text = machine_state.values

    if register.is_value?
      return MachineState.new(pc+1, a, b, c, d, text)
    end

    case register.name
    when 'a'
      return MachineState.new(pc+1, a+1, b, c, d, text)
    when 'b'
      return MachineState.new(pc+1, a, b+1, c, d, text)
    when 'c'
      return MachineState.new(pc+1, a, b, c+1, d, text)
    when 'd'
      return MachineState.new(pc+1, a, b, c, d+1, text)
    end
  end

  def toggle
    Dec.new(register)
  end
end

class Dec
  def execute(machine_state)
    pc, a, b, c, d, text = machine_state.values

    if register.is_value?
      return MachineState.new(pc+1, a, b, c, d, text)
    end

    case register.name
    when 'a'
      return MachineState.new(pc+1, a-1, b, c, d, text)
    when 'b'
      return MachineState.new(pc+1, a, b-1, c, d, text)
    when 'c'
      return MachineState.new(pc+1, a, b, c-1, d, text)
    when 'd'
      return MachineState.new(pc+1, a, b, c, d-1, text)
    end
  end

  def toggle
    Inc.new(register)
  end
end

class Jnz
  def execute(machine_state)
    source.do_jump(distance, machine_state)
  end

  def toggle
    Cpy.new(source, distance)
  end
end

class Tgl
  attr_reader :target

  def execute(machine_state)
    pc, a, b, c, d, text = machine_state.values
    set_target(machine_state)

    return MachineState.new(pc+1, a, b, c, d, text) if out_of_bounds?

    # Update text, not copy
    text[target] = text[target].toggle

    MachineState.new(pc+1, a, b, c, d, text)
  end

  def out_of_bounds?
    @target < 0 || @target >= @instructions
  end

  def set_target(machine_state)
    @target = machine_state.pc + distance.value(machine_state)
    @instructions = machine_state.text.size
  end

  def toggle
    Inc.new(distance)
  end
end

@example = <<-INSTRUCTIONS
cpy 2 a
tgl a
tgl a
tgl a
cpy 1 a
dec a
dec a
INSTRUCTIONS

@input = <<-INSTRUCTIONS
cpy a b
dec b
cpy a d
cpy 0 a
cpy b c
inc a
dec c
jnz c -2
dec d
jnz d -5
dec b
cpy b c
cpy c d
dec d
inc c
jnz d -2
tgl c
cpy -16 c
jnz 1 c
cpy 96 c
jnz 79 d
inc a
inc d
jnz d -2
inc c
jnz c -5
INSTRUCTIONS