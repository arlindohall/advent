
class Scrambler
  def initialize(instructions, password)
    @instructions = instructions.map(&method(:parse))
    @password = password.chars
  end

  def parse(line)
    first, second, *rest = line.split
    case [first, second].join(' ')
    when "swap position"
      SwapPosition.new(rest.first.to_i, rest.last.to_i)
    when "swap letter"
      SwapLetter.new(rest.first, rest.last)
    when "rotate left"
      Rotate.new(rest.first.to_i)
    when "rotate right"
      Rotate.new(-rest.first.to_i)
    when "rotate based"
      RotateLetter.new(rest.last)
    when "reverse positions"
      Reverse.new(rest.first.to_i, rest.last.to_i)
    when "move position"
      Move.new(rest.first.to_i, rest.last.to_i)
    else
      raise "Unknown instruction: #{line}"
    end
  end

  def scramble
    @instructions.each do |instruction|
      printf "before=%s, ", @password.join
      instruction.call(@password)
      printf "after=%s\n", @password.join
    end
    @password.join
  end

  def unscramble
    @instructions.reverse.each do |instruction|
      printf "before=%s, ", @password.join
      instruction.reverse(@password)
      printf "after=%s\n", @password.join
    end
    @password.join
  end
end

SwapPosition = Struct.new(:x, :y)
SwapLetter = Struct.new(:a, :b)
Rotate = Struct.new(:steps_left)
RotateLetter = Struct.new(:letter)
Reverse = Struct.new(:x, :y)
Move = Struct.new(:x, :y)

class SwapPosition
  def call(password)
    password[x], password[y] = password[y], password[x]
  end

  def reverse(password)
    call(password)
  end
end

class SwapLetter
  def call(password)
    x, y = password.index(a), password.index(b)
    password[x], password[y] = password[y], password[x]
  end

  def reverse(password)
    call(password)
  end
end

class Rotate
  def call(password)
    password.rotate!(steps_left)
  end

  def reverse(password)
    password.rotate!(-steps_left)
  end
end

class RotateLetter
  def call(password)
    steps_right = adjusted_position(password)
    password.rotate!(-steps_right)
  end

  def reverse(password)
    steps_left = adjusted_reversed(password)
    password.rotate!(steps_left)
  end

  <<-scratch
  We know the password can only be 8 long, so we can calculate the final position for each.h
  The destination of the character is...
    0 => 1
    1 => 3
    2 => 5
    3 => 7
    4 => 10
    5 => 12
    6 => 14
    7 => 16

  Mod 8 these become
    0 => 1    => 1
    1 => 3    => 3
    2 => 5    => 5
    3 => 7    => 7
    4 => 10   => 2
    5 => 12   => 4
    6 => 14   => 6
    7 => 16   => 0

  Then we can just lookup the left rotation to get there...
    1 => 1 - 0 = 1
    3 => 3 - 1 = 2
    5 => 5 - 2 = 3
    7 => 7 - 3 = 4
    2 => 2 - 4 = -2
    4 => 4 - 5 = -1
    6 => 6 - 6 = 0
    0 => 0 - 7 = -7 => 1
  scratch
  def adjusted_reversed(password)
    case password.index(letter)
    when 1 then 1
    when 3 then 2
    when 5 then 3
    when 7 then 4
    when 2 then -2
    when 4 then -1
    when 6 then 0
    when 0 then 1
    end
  end

  def adjusted_position(password)
    if position(password) >= 4
      position(password) + 2
    else
      position(password) + 1
    end
  end

  def position(password)
    password.index(letter)
  end
end

class Reverse
  def call(password)
    @start, @finish = [x, y].sort
    while @start <= @finish
      password[@start], password[@finish] = password[@finish], password[@start]
      @start += 1
      @finish -= 1
    end
  end

  def reverse(password)
    call(password)
  end
end

class Move
  def call(password)
    @start, @finish = x, y
    for i in swap_range
      password[i], password[i+@swap_direction] =
        password[i+@swap_direction], password[i]
    end
  end

  def reverse(password)
    Move.new(y, x).call(password)
  end

  def swap_range
    if @start <= @finish
      @swap_direction = 1
      @start.upto(@finish-1)
    else
      @swap_direction = -1
      @start.downto(@finish+1)
    end
  end
end

@example = <<-EOF.strip.lines.map(&:strip)
  swap position 4 with position 0
  swap letter d with letter b
  reverse positions 0 through 4
  rotate left 1 step
  move position 1 to position 4
  move position 3 to position 0
  rotate based on position of letter b
  rotate based on position of letter d
EOF

@input = <<-EOF.strip.lines.map(&:strip)
  move position 2 to position 6
  move position 0 to position 5
  move position 6 to position 4
  reverse positions 3 through 7
  move position 1 to position 7
  swap position 6 with position 3
  swap letter g with letter b
  swap position 2 with position 3
  move position 4 to position 3
  move position 6 to position 3
  swap position 4 with position 1
  swap letter b with letter f
  reverse positions 3 through 4
  swap letter f with letter e
  reverse positions 2 through 7
  rotate based on position of letter h
  rotate based on position of letter a
  rotate based on position of letter e
  rotate based on position of letter h
  rotate based on position of letter c
  move position 5 to position 7
  swap letter a with letter d
  move position 5 to position 6
  swap position 4 with position 0
  swap position 4 with position 6
  rotate left 6 steps
  rotate right 4 steps
  rotate right 5 steps
  swap letter f with letter e
  swap position 2 with position 7
  rotate based on position of letter e
  move position 4 to position 5
  swap position 4 with position 2
  rotate right 1 step
  swap letter b with letter f
  rotate based on position of letter b
  reverse positions 3 through 5
  move position 3 to position 1
  rotate based on position of letter g
  swap letter c with letter e
  swap position 7 with position 3
  move position 0 to position 3
  rotate right 6 steps
  reverse positions 1 through 3
  swap letter d with letter e
  reverse positions 3 through 5
  move position 0 to position 3
  swap letter c with letter e
  move position 2 to position 7
  swap letter g with letter b
  rotate right 0 steps
  reverse positions 1 through 3
  swap letter h with letter d
  move position 4 to position 0
  move position 6 to position 3
  swap letter a with letter c
  reverse positions 3 through 6
  swap letter h with letter g
  move position 7 to position 2
  rotate based on position of letter h
  swap letter b with letter h
  reverse positions 2 through 6
  move position 6 to position 7
  rotate based on position of letter a
  rotate right 7 steps
  reverse positions 1 through 6
  move position 1 to position 6
  rotate based on position of letter g
  rotate based on position of letter d
  move position 0 to position 4
  rotate based on position of letter e
  rotate based on position of letter d
  rotate based on position of letter a
  rotate based on position of letter a
  rotate right 4 steps
  rotate based on position of letter b
  reverse positions 0 through 4
  move position 1 to position 7
  rotate based on position of letter e
  move position 1 to position 7
  swap letter f with letter h
  move position 5 to position 1
  rotate based on position of letter f
  reverse positions 0 through 1
  move position 2 to position 4
  rotate based on position of letter a
  swap letter b with letter d
  move position 6 to position 0
  swap letter e with letter b
  rotate right 7 steps
  move position 2 to position 7
  rotate left 4 steps
  swap position 6 with position 1
  move position 3 to position 5
  rotate right 7 steps
  reverse positions 0 through 6
  swap position 2 with position 1
  reverse positions 4 through 6
  rotate based on position of letter g
  move position 6 to position 4
EOF