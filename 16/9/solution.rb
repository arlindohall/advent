
Part = Struct.new(:text)
Expansion = Struct.new(:characters, :times)

class Message
  def initialize(text)
    @text = text
  end

  def parse
    @tokens = []
    @index = 0
    tokenize
  end

  private

  def tokenize
    while !at_end?
      case current
      when '('
        @tokens << read_expansion
      else
        @tokens << read_part
      end
    end
    @tokens = @tokens.compact
  end

  def read_expansion
    start = @index+1
    until current == ')'
      @index += 1
    end
    characters, times = @text[start..@index].split('x').map(&:to_i)
    @index += 1
    Expansion.new(characters, times)
  end

  def read_part
    start = @index
    until at_end? || current == '('
      @index += 1
    end
    Part.new(@text[start..@index-1])
  end

  def current
    @text[@index]
  end

  def at_end?
    @index >= @text.length
  end

end

@example = <<-END.strip.lines.map(&:strip)
  ADVENT
  A(1x5)BC
  (3x3)XYZ
  A(2x2)BCD(2x2)EFG
  (6x1)(1x3)A
  X(8x2)(3x3)ABCY
END