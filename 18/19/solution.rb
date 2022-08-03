
Instruction = Struct.new(:name, :a, :b, :c)

DebugFrequency = 10_000_000

class Instruction
  def to_s
    values.map(&:to_s).join(' ')
  end
end

class Watch
  attr_reader :registers
  def initialize(instructions, registers, ip, ip_reg)
    @instructions = instructions
    @registers = registers
    @ip = ip
    @ip_reg = ip_reg
  end

  def self.parse(text)
    instructions = text.strip.split("\n").map { |line|
      if line.start_with?('#ip ')
        reg = /#ip (\d+)/.match(line).captures.first
        Instruction[:ip, reg.to_i]
      else
        name, *regs = line.split
        a, b, c = regs.map(&:to_i)
        Instruction[name.to_sym, a, b, c]
      end
    }

    ip_directive = instructions.first
    instructions = instructions.drop(1)
    new(
      instructions,
      6.times.map { 0 },
      0,
      ip_directive.a,
    )
  end

  def execute
    @i = 0
    until out_of_range?
      puts @i if (@i += 1) % DebugFrequency == 0
      apply
    end

    debug_post
  end

  def new_process
    @registers[0] = 1
    execute
  end

  def out_of_range?
    @ip < 0 || @ip >= @instructions.size
  end

  def apply
    @registers[@ip_reg] = @ip

    @instruction = @instructions[@ip]
    debug_pre if @i % DebugFrequency == 0

    _apply
    debug_post if @i % DebugFrequency == 0
  end

  def debug_pre
    print "ip=#{@ip}, #{@registers.inspect}, #{@instruction.to_s}, "
  end

  def debug_post
    puts @registers.inspect
  end

  def _apply
    value = case @instruction.name
    when :addr
      register(@instruction.a) + register(@instruction.b)
    when :addi
      register(@instruction.a) + @instruction.b
    when :mulr
      register(@instruction.a) * register(@instruction.b)
    when :muli
      register(@instruction.a) * @instruction.b
    when :banr
      register(@instruction.a) & register(@instruction.b)
    when :bani
      register(@instruction.a) & @instruction.b
    when :borr
      register(@instruction.a) | register(@instruction.b)
    when :bori
      register(@instruction.a) | @instruction.b
    when :setr
      register(@instruction.a)
    when :seti
      @instruction.a
    when :gtir
      @instruction.a > register(@instruction.b) ? 1 : 0
    when :gtri
      register(@instruction.a) > @instruction.b ? 1 : 0
    when :gtrr
      register(@instruction.a) > register(@instruction.b) ? 1 : 0
    when :eqir
      @instruction.a == register(@instruction.b) ? 1 : 0
    when :eqri
      register(@instruction.a) == @instruction.b ? 1 : 0
    when :eqrr
      register(@instruction.a) == register(@instruction.b) ? 1 : 0
    else
      raise "Unknown instruction name #{@instruction.name}"
    end

    @registers[@instruction.c] = value

    @ip = @registers[@ip_reg] + 1
  end

  def register(i)
    @registers[i]
  end
end

# I could tell the solution involved counting to the number N, N times,
# and there's a comparison and setting the first register to +1 some
# number of times, which is probably addition. Then I tried seeing what
# the factors of the N register were and it turns out the solution to part
# 1 was the sum of those factors. I don't know how the N register is set,
# but it doesn't really matter becasue ti basically stays teh same for the
# whole execution.
#
# I could add to the top part some logic to run the puzzle for like 10
# steps and infer the value of N, or I can just run it and interrupt
# on the first debug output, which I did.
def solve(i)
  factors(i).sum
end

def factors(i)
  f = []
  1.upto(Math.sqrt(i).floor) { |factor|
    if i % factor == 0
      f << factor 
      f << i / factor
    end
  }

  f
end

solve(10551517) # := 10551517 -> too low

@example = <<-inst
#ip 0
seti 5 0 1
seti 6 0 2
addi 0 1 0
addr 1 2 3
setr 1 0 0
seti 8 0 4
seti 9 0 5
inst

@input = <<-inst
#ip 5
addi 5 16 5
seti 1 8 2
seti 1 1 1
mulr 2 1 4
eqrr 4 3 4
addr 4 5 5
addi 5 1 5
addr 2 0 0
addi 1 1 1
gtrr 1 3 4
addr 5 4 5
seti 2 8 5
addi 2 1 2
gtrr 2 3 4
addr 4 5 5
seti 1 7 5
mulr 5 5 5
addi 3 2 3
mulr 3 3 3
mulr 5 3 3
muli 3 11 3
addi 4 6 4
mulr 4 5 4
addi 4 5 4
addr 3 4 3
addr 5 0 5
seti 0 0 5
setr 5 3 4
mulr 4 5 4
addr 5 4 4
mulr 5 4 4
muli 4 14 4
mulr 4 5 4
addr 3 4 3
seti 0 3 0
seti 0 0 5
inst