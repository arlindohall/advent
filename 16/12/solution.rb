
Cpy = Struct.new(:source, :dest)
Inc = Struct.new(:register)
Dec = Struct.new(:register)
Jnz = Struct.new(:source, :distance)
Register = Struct.new(:name)
Value = Struct.new(:itself)

class Computer
  def initialize(instructions)
    @instructions = instructions
      .strip
      .lines
      .map(&:strip)
  end

  def run_part1
    compile
    reset_registers
    while in_bounds?
      execute_current
    end
    puts "pc=#{@pc} a=#{@a} b=#{@b} c=#{@c} d=#{@d}"
  end

  def run_part2
    compile
    reset_registers
    @c = 1
    while in_bounds?
      execute_current
    end
    puts "pc=#{@pc} a=#{@a} b=#{@b} c=#{@c} d=#{@d}"
  end

  def in_bounds?
    @pc >= 0 && @pc < @instructions.size
  end

  def execute_current
    # puts "pc=#{@pc} a=#{@a} b=#{@b} c=#{@c} d=#{@d}, current=#{current}"
    @pc, @a, @b, @c, @d = current.execute(@pc, @a, @b, @c, @d)
  end

  def current
    @compiled[@pc]
  end

  def reset_registers
    @pc, @a, @b, @c, @d = 0, 0, 0, 0, 0
  end

  def compile
    @compiled = @instructions.map{|i| parse(i)}
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
    end
  end

  def copy(left, right)
    Cpy.new(value_or_register(left), right)
  end

  def inc(left)
    Inc.new(left)
  end

  def dec(left)
    Dec.new(left)
  end

  def jnz(left, right)
    Jnz.new(value_or_register(left), right.to_i)
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
  def do_jump(distance, pc, a, b, c, d)
    if value(a, b, c, d) == 0
      return pc+1, a, b, c, d
    else
      return pc+distance, a, b, c, d
    end
  end
end

class Register
  include DoJump

  def value(a, b, c, d)
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
end

class Value
  include DoJump

  def value(a, b, c, d)
    itself
  end
end

class Cpy
  def execute(pc, a, b, c, d)
    case dest
    when 'a'
      return pc+1, source.value(a, b, c, d), b, c, d
    when 'b'
      return pc+1, a, source.value(a, b, c, d), c, d
    when 'c'
      return pc+1, a, b, source.value(a, b, c, d), d
    when 'd'
      return pc+1, a, b, c, source.value(a, b, c, d)
    end
  end
end

class Inc
  def execute(pc, a, b, c, d)
    case register
    when 'a'
      return pc+1, a+1, b, c, d 
    when 'b'
      return pc+1, a, b+1, c, d 
    when 'c'
      return pc+1, a, b, c+1, d 
    when 'd'
      return pc+1, a, b, c, d+1
    end
  end
end

class Dec
  def execute(pc, a, b, c, d)
    case register
    when 'a'
      return pc+1, a-1, b, c, d 
    when 'b'
      return pc+1, a, b-1, c, d 
    when 'c'
      return pc+1, a, b, c-1, d 
    when 'd'
      return pc+1, a, b, c, d-1
    end
  end
end

class Jnz
  def execute(pc, a, b, c, d)
    source.do_jump(distance, pc, a, b, c, d)
  end
end

@example = <<-INSTRUCTIONS
cpy 41 a
inc a
inc a
dec a
jnz a 2
dec a
INSTRUCTIONS

@input = <<-INSTRUCTIONS
cpy 1 a
cpy 1 b
cpy 26 d
jnz c 2
jnz 1 5
cpy 7 c
inc d
dec c
jnz c -2
cpy a c
inc a
dec b
jnz b -2
cpy c b
dec d
jnz d -6
cpy 13 c
cpy 14 d
inc a
dec d
jnz d -2
dec c
jnz c -5
INSTRUCTIONS