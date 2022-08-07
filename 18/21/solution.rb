
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
    puts [@registers[0], @registers[4]].inspect if @ip == 29
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

  def with_register_0(value)
    @registers[0] = value
    self
  end
end

def run(value = 1_000_000_000_000)
  Watch.parse(@example).with_register_0(value).execute
end

# The analyses below don't really solve the problem, instead I just
# added a debug print of the regs 0 and 4 when the ip is 29 so I can
# see what value will escape the loop. I made a mistake in the decompilation.


# - : #ip 3                     ; <- set ip to track r3
# 0 : seti 123 0 4              ; r4 := 123
# 1 : bani 4 456 4              ; r4 &= 456
# 2 : eqri 4 72 4               ; r4 := r4 == 72 ? 1 : 0
# 3 : addr 4 3 3                ; jump_if (r4 == 1) 4 else 5
# 4 : seti 0 0 3                ; jump 1
# 5 : seti 0 6 4                ; r4 := 0
# 6 : bori 4 65536 1            ; r1 := r4 | 65536 (0x1_00_00)
# 7 : seti 678134 1 4           ; r4 := 678134 (0xa_58_f6)
# 8 : bani 1 255 5              ; r5 := r1 & 255
# 9 : addr 4 5 4                ; r4 += r5
# 10: bani 4 16777215 4         ; r4 &= 16777215 (0xff_ff_ff)
# 11: muli 4 65899 4            ; r4 *= 65899 (0x1016b)
# 12: bani 4 16777215 4         ; r4 &= 16777215 (0xff_ff_ff)
# 13: gtir 256 1 5              ; r5 := 256 > r1 ? 1 : 0
# 14: addr 5 3 3                ; jump_if (r5 == 1) 16 else 15
# 15: addi 3 1 3                ; jump 17
# 16: seti 27 8 3               ; jump 28
# 17: seti 0 1 5                ; r5 := 0
# 18: addi 5 1 2                ; r2 := r5 + 1
# 19: muli 2 256 2              ; r2 *= 256                         <- r2 = r2 << 8
# 20: gtrr 2 1 2                ; r2 = r2 > r1 ? 1 : 0
# 21: addr 2 3 3                ; jump_if (r2 == 1) 23 else 22
# 22: addi 3 1 3                ; jump 24
# 23: seti 25 7 3               ; jump 26
# 24: addi 5 1 5                ; r5 += 1
# 25: seti 17 1 3               ; jump 18
# 26: setr 5 3 1                ; r1 := r5
# 27: seti 7 8 3                ; jump 8
# 28: eqrr 4 0 5                ; r5 = r4 == r0 ? 1 : 0
# 29: addr 5 3 3                ; jump_if (r5 == 1) 31 else 30
# 30: seti 5 4 3                ; jump 6

#   - : <- set ip to track r3
#   5 : r4 := 0
# x 6 : r1 := r4 | 65536 (0x1_00_00)
#   7 : r4 := 678134 (0xa_58_f6)
# x 8 : r5 := r1 & 255
#   9 : r4 += r5
#   10: r4 &= 16777215 (0xff_ff_ff)
#   11: r4 *= 65899 (0x1016b)
#   12: r4 &= 16777215 (0xff_ff_ff)
#   13: r5 := 256 > r1 ? 1 : 0
#   14: jump_if (r5 == 1) 16 else 15 <- get to 16 from here if r1 < 256, which is always true first time, line 8 sets to 255
# x 15: jump 17
# x 16: jump 28 <- get to escape clause here
# x 17: r5 := 0
# x 18: r2 := r5 + 1
#   19: r2 *= 256                         <- r2 = r2 << 8
#   20: r2 = r2 > r1 ? 1 : 0
#   21: jump_if (r2 == 1) 23 else 22
# x 22: jump 24
# x 23: jump 26
# x 24: r5 += 1
#   25: jump 18
# x 26: r1 := r5
#   27: jump 8
# x 28: r5 = r4 == r0 ? 1 : 0
#   29: jump_if (r5 == 1) 31 else 30 <- escape here if r4 == r0
# x 30: jump 6

#   - : <- set ip to track r3
#   5 : r4 := 0
# x 6 : loop do
#         r1 := r4 | 65536
#   7 :   r4 := 678134
# x 8 :   loop do 
#           r5 := r1 & 255
#   12:     r4 := (((r4 + r5) & 16777215) * 65899) & 16777215
# x 16:     halt! if (256 > r1) && (r4 == r0)
# x 17:     r1 := r1 * 256
#   27:   end
# x 30: end


# dead code?
# x 18:     do
#   19:       r2 := (r5 + 1) * 256
#   21:       if (r2 <= r1)
# x 24:         r5 += 1 ; end
# x 26:     until (r2 > r1) ; r1 := r5
  
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