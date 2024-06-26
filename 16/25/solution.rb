
Cpy = Struct.new(:source, :dest)
Jnz = Struct.new(:source, :distance)
Inc = Struct.new(:register)
Dec = Struct.new(:register)
Tgl = Struct.new(:distance)
Out = Struct.new(:value)

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
    when "out"
      out(left)
    end
  end

  def find
    for i in (0..)
      $output = []
      run(i)
      if $output.join == "01" * 10 || $output.join == "10" * 10
        return i
      end
      puts $output.join
    end
  end

  def run(i, steps = 20)
    reset_registers
    @machine_state.a = i
    while $output.size < steps
      # p [@machine_state.values.take(5), current]
      execute_current
    end
    # puts "machine_state=#{@machine_state}"
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

  def out(left)
    Out.new(value_or_register(left))
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

class Out
  def execute(machine_state)
    pc, a, b, c, d, text = machine_state.values
    $output << value.value(machine_state)
    return MachineState.new(pc+1, a, b, c, d, text)
  end
end

@input = <<-INSTRUCTIONS
cpy a d
cpy 14 c
cpy 182 b
inc d
dec b
jnz b -2
dec c
jnz c -5
cpy d a
jnz 0 0
cpy a b
cpy 0 a
cpy 2 c
jnz b 2
jnz 1 6
dec b
dec c
jnz c -4
inc a
jnz 1 -7
cpy 2 b
jnz c 2
jnz 1 4
dec b
dec c
jnz 1 -4
jnz 0 0
out b
jnz a -19
jnz 1 -21
INSTRUCTIONS