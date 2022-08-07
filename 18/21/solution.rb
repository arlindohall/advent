
Instruction = Struct.new(:name, :a, :b, :c)
DebugFrequency = 1_000_000_000

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
    print "ip=#{@ip},".ljust(5) +
      "#{@registers.inspect},".ljust(50) +
      "#{@instruction.to_s},".ljust(20)
  end

  def debug_post
    puts @registers.inspect
  end

  def _apply
    look_for_cycle
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

  def look_for_cycle
    return if @ip != 29

    reg0 = @registers[0]
    reg4 = @registers[4]
    @seen ||= []

    raise "Found cycle: #{@seen.last}" if @seen.include?(reg4)

    @seen << reg4
    puts "r0=#{reg0}, r4=#{reg4}, cycles=#{@seen.size} (check=#{@seen.uniq.size})"
  end

  def register(i)
    @registers[i]
  end

  def with_register_0(value)
    @registers[0] = value
    self
  end
end

def run(value = 1)
  Watch.parse(@example).with_register_0(value).execute
end

=begin
The key to the solution is recognizing that the only jump instruction that
exits the loop is on line 29, so you can just print the value of registers
0 and 4 when the IP is at that value. Then to solve, just call `run(1)` or
really `run` with any value that doesn't halt, and see what happens.

For part 2, just keep track of the values in the registers, and the first
time there's a cycle, print the one before. (runs in ~8min with truffleruby)
=end

@example = <<-inst.strip
#ip 3
seti 123 0 4
bani 4 456 4
eqri 4 72 4
addr 4 3 3
seti 0 0 3
seti 0 6 4
bori 4 65536 1
seti 678134 1 4
bani 1 255 5
addr 4 5 4
bani 4 16777215 4
muli 4 65899 4
bani 4 16777215 4
gtir 256 1 5
addr 5 3 3
addi 3 1 3
seti 27 8 3
seti 0 1 5
addi 5 1 2
muli 2 256 2
gtrr 2 1 2
addr 2 3 3
addi 3 1 3
seti 25 7 3
addi 5 1 5
seti 17 1 3
setr 5 3 1
seti 7 8 3
eqrr 4 0 5
addr 5 3 3
seti 5 4 3
inst