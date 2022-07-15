
class Tape
  def initialize
    @negative = [0]
    @positive = [0]
  end

  def checksum
    @positive.sum + @negative.sum
  end

  def read(cursor)
    if cursor.zero?
      @positive[0]
    elsif cursor.negative? && cursor.abs > @negative.size - 1
      (@negative << 0).last
    elsif cursor.negative?
      @negative[cursor.abs]
    elsif cursor.positive? && cursor > @positive.size - 1
      (@positive << 0).last
    else
      @positive[cursor]
    end
  end

  def set(cursor, value)
    if cursor.zero?
      @positive[0] = value
    elsif cursor.negative? && cursor.abs > @negative.size - 1
      (@negative << 0)[cursor.abs] = value
    elsif cursor.negative?
      @negative[cursor.abs] = value
    elsif cursor.positive? && cursor > @positive.size - 1
      (@positive << 0)[cursor] = value
    else
      @positive[cursor] = value
    end
  end
end

class TuringMachine
  def initialize
    @cursor = 0
    @state = :a
    @tape = Tape.new
  end

  def exec(steps = 12794428)
    @i = 0
    steps.times { run; debug }
    @tape.checksum
  end

  def debug
    p @i if (@i += 1) % 100_000 == 0
  end

  def run
    send(@state)
  end

  def current
    @tape.read(@cursor)
  end

  def write(val)
    @tape.set(@cursor, val)
  end

  def move(direction)
    if direction == :right
      @cursor += 1
    else
      @cursor -= 1
    end
  end

  def state(new_state)
    @state = new_state
  end

  def a
    if current == 0
      write(1)
      move(:right)
      state(:b)
    else
      write(0)
      move(:left)
      state(:f)
    end
  end

  def b
    if current == 0
      write(0)
      move(:right)
      state(:c)
    else
      write(0)
      move(:right)
      state(:d)
    end
  end

  def c
    if current == 0
      write(1)
      move(:left)
      state(:d)
    else
      write(1)
      move(:right)
      state(:e)
    end
  end

  def d
    if current == 0
      write(0)
      move(:left)
      state(:e)
    else
      write(0)
      move(:left)
      state(:d)
    end
  end

  def e
    if current == 0
      write(0)
      move(:right)
      state(:a)
    else
      write(1)
      move(:right)
      state(:c)
    end
  end

  def f
    if current == 0
      write(1)
      move(:left)
      state(:a)
    else
      write(1)
      move(:right)
      state(:a)
    end
  end
end