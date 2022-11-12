
require_relative '../intcode'

class Springscript
  def initialize(intcode)
    @intcode = intcode
  end

  def move(pgm)
    @intcode = @intcode.dup

    pgm.each { |ch| @intcode.send_signal(ch) }
    @intcode.send_signal("\n".ord)

    @intcode.interpret!

    signals = @intcode.receive_signals
    puts signals.filter { |ch| ch <= 127 }.pack('c*') if signals.size > 1
    puts signals.filter { |ch| ch > 127 }
  end

  def walk
    move(program_simple("WALK"))
  end

  def run
    move(program_run)
  end

  """
  program_run----
  would_jump && jump_will_not_trap

  would_jump----(old function)
  must_jump_soon && can_jump_safely
  d && !(a && b && c)

  must_jump_soon----
  !(a && b && c)

  can_jump_safely----
  d

  jump_will_not_trap----
  !(must_jump_at_d && cannot_jump_safely_at_d)
  !(!e && !h)->(e || h)

  must_jump_at_d----
  !e

  cannot_jump_safely_at_d----
  !h

  (d && !(a && b && c)) && (e || h)
  ((d && !(a && b && c)) && e) || ((d && !(a && b && c)) && h)
  ((d && !(a && b && c)) && e) || ((d && !(a && b && c)) && h)
  """
  def program_run
    springscript = []
    # J = d && !(a && b && c) --- old function
    springscript << "OR A T"
    springscript << "AND B T"
    springscript << "AND C T"
    springscript << "NOT T T"
    springscript << "AND D T"
    springscript << "OR T J"
    # T == J
    springscript << "OR E T"
    springscript << "AND E T"
    springscript << "OR H T"
    springscript << "AND T J"
    springscript << "RUN"

    springscript.join("\n").chars.map(&:ord)
  end

  def program_simple(start)
    <<~SPRINGSCRIPT.strip.chars.map(&:ord)
      OR A T
      AND B T
      AND C T
      NOT T T
      AND D T
      OR T J
      #{start}
    SPRINGSCRIPT
  end

  def program(start)
    <<~SPRINGSCRIPT.strip.chars.map(&:ord)
      OR A T
      NOT T T
      AND D T
      OR T J
      OR B T
      NOT T T
      AND D T
      OR T J
      OR C T
      NOT T T
      AND D T
      OR T J
      #{start}
    SPRINGSCRIPT
  end

  def program_ruby(a, b, c, d)
    t, j = false, false
    t = a || t
    t = ! t
    t = d && t
    j = t || j
    t = b || t
    t = ! t
    t = d && t
    j = t || j
    t = c || t
    t = ! t
    t = d && t
    j = j || t
  end

  """
  Using truth table, the simplified version is
  
  jump if !(!d || (a && b && c))
  jump if d && !(a && b && c)
  """
  def truth_table
    puts %w(a b c d answer).join(" " * 5)
    [*4.times.map { true }, *4.times.map { false }]
      .permutation(4)
      .uniq
      .each do |args|
        a, b, c, d = args
        answer = program_ruby(a, b, c, d)

        # Debugging, making table smaller
        # next if !d
        # next if answer

        args.each { |a| print a.to_s.ljust(6) }

        raise "D is false and J is true" if !d && answer
        puts answer
      end
  end

  def program_run_ruby(a, b, c, d, e, f, g, h, i)
    # (d && !(a && b && c)) && !(!e && f && !g && !h && i)
    # (d && !(a && b && c)) && (e || !f || g || h || !i)
    # (d && !(a && b && c)) && (e || !f || g || h || !i)
  end

  def truth_table_run
    puts %w(a b c d e f g h i answer).join(" " * 5)
    arguments(9)
      .each do |args|
        a, b, c, d, e, f, g, h, i = args
        answer = program_run_ruby(a, b, c, d, e, f, g, h, i)

        next if answer == c

        args.each { |a| print a.to_s.ljust(6) }

        puts answer
      end
    nil
  end

  def arguments(n)
    return [true, false] if n == 1
    arguments(n - 1).flat_map { |args|
      [
        [*args, true],
        [*args, false],
      ]
    }
  end

  def self.parse(text)
    new(IntcodeProgram.parse(text))
  end
end

def solve
  Springscript.parse(@input).walk
  Springscript.parse(@input).run
end

begin
  @input = File.read("#{Pathname.new(__FILE__).dirname.to_s}/input.txt")
rescue
  @input = File.read("19/21/input.txt")
end