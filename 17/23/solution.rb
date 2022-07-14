
require 'ostruct'

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

  def solve
  end

  def dup
    self.class.new(@instructions.dup)
  end

  <<-doc
  We're trying to figure out what is in 'h' at the end.

  Clearly the goal of the first subroutine is to get d, e to equal
  b, c, and we multiply those together somehow, and also set h
  equal to some operation of those.

  We could try setting b, c at the beginning of the program to like
  1 and 2 and see what we get in h, that would be instructive.
  doc
  def single(a = 0)
    @pc, @mul, @reg, @done = 0, 0, {a:}, ''
    until done?
      # p [@pc, @mul, @reg]
      count_mulitplys
      interpret
    end
    [@reg, @mul]
  end

  def count_mulitplys
    if current.op == :mul
      @mul += 1
    end
  end

  def done?
    @pc < 0 || @pc >= @instructions.size
  end

  def interpret
    case current.op
    when :set
      set(current.target, value_of(current.source))
    when :mul
      set(current.target, value_of(current.target) * value_of(current.source))
    when :jnz
      if value_of(current.target) != 0
        @pc += value_of(current.source)
        return
      end
    when :sub
      set(current.target, value_of(current.target) - value_of(current.source))
    else
      raise "Unknown op: #{current.op}"
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

    if val.respond_to?(:number)
      val.number
    elsif val.respond_to?(:register)
      @reg[val.register] ||= 0
    else
      raise "Unknown value: #{val}"
    end
  end

  def set(reg, val)
    @reg[reg.register] = val
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
      OpenStruct.new({ number: value.to_i })
    when /\w/
      OpenStruct.new({ register: value.to_sym })
    else
      raise "Unknown value or register: #{value}"
    end
  end
end

<<-exp
Using these numbers, h = 2

That's because on line 7, we set c to b + 85, in other words
the program increases b however many times it takes to equal
c, then that number of times is h. But b is set to some value,
and incremented by groups of 17*2

So basically h_final * 34 + b_initial == c_initial.

And b_initial is the value of b the first time we get to inst
25, c_initial is the value of c the first time we get to inst
25, so we can use the actual input to find those two.

b_initial = 109900, c_initial = 126900
h_final * 34 + 109900 == 126900

h_final = (126900 - 109900) / 34

h_final = 500 <- website says this is too low, though so I'm confused

Okay starting over...

we're looking for f(x1, x2, x3, x4) = h

what we get is setting

b=> b_init * b_mul + sub_b
c=> 17*n

then we do some thing with d/e until b == c and
then we return h. The things we do with d/e is
increment e until it's d, then increment d, and
do that x times until d is equal to b. Then if
c is equal to b, we output h. And I think we
increment h as many times as we increment b
until it equals c.


So maybe it's h = (sub_c)

Okay by trying to actually just set b, I noticed
that the value of b when we get to the first loop has
to be at least 3...

So the output must be some funciton of f(x,y)

[1,2,3,4,5,6,7].combination(2).flat_map(&:permutation).flat_map(&:to_a).map{|x,y| [[x,y],Duet.of(@input[x,y])]
}.map{|v,d| p [v, d.single(1).first[:h]]}.map{nil}.compact

Above does not give a sensible equation, so I'll try to simplify

function(b, n)
  c = b+17*n
  non_primes = 0
  for b in b..c {
    found_factor = false
    catch(:found) {
      for d in 2...Math.sqrt(b).floor
        for e in 2...(1.0*b/d).floor
          if d * e == b
            found_factor = true
            throw :found
          end
        end
      end
    }
    non_primes += 1 if found_g_zero
  end
  primes
end

Now just find the arguments b & n
b = 109900
c = b + (17 * 1000)
-> n = 1000
inst
exp
# @input = ->(b_init, sub_c) {<<-inst
# set b #{b_init + 2}
# set c b
# sub c -#{sub_c * 17}
# set f 1
# set d 2
# set e 2
# set g d
# mul g e
# sub g b
# jnz g 2
# set f 0
# sub e -1
# set g e
# sub g b
# jnz g -8
# sub d -1
# set g d
# sub g b
# jnz g -13
# jnz f 2
# sub h -1
# set g b
# sub g c
# jnz g 2
# jnz 1 3
# sub b -17
# jnz 1 -23
# inst
# }

@input = <<-inst
set b 99
set c b
jnz a 2
jnz 1 5
mul b 100
sub b -100000
set c b
sub c -17000
set f 1
set d 2
set e 2
set g d
mul g e
sub g b
jnz g 2
set f 0
sub e -1
set g e
sub g b
jnz g -8
sub d -1
set g d
sub g b
jnz g -13
jnz f 2
sub h -1
set g b
sub g c
jnz g 2
jnz 1 3
sub b -17
jnz 1 -23
inst

def function(b, n)
  c = b+17*n
  non_primes = 0
  for b in (n+1).times.map{|i| b+i*17}
    puts b if b % 10 == 0
    found_factor = false
    catch(:found) {
      for d in 2..Math.sqrt(b).floor
        for e in 2..(1.0*b/d).floor
          if d * e == b
            found_factor = true
            throw :found
          end
        end
      end
    }
    if found_factor
      non_primes += 1
    end
  end
  non_primes
end

def part2
  function(109900, 1000)
end