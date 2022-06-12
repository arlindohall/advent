
class Message
  def initialize(text)
    @text = text
  end

  def expand
    @text
    while expandable?
      expand_once
    end
  end

  def expand_once
    return self if !expandable?

    characters, times, start, _end = first_group

    beginning = @text[0...start]
    expansion = times.times.map{ @text[_end..._end + characters] }.join
    rest = @text[_end + characters..-1]

    @text = beginning + expansion + rest

    self
  end

  def expandable?
    !first_group.nil?
  end

  def first_group
    @index = 0
    until at_end? || current == '('
      @index += 1
    end

    return if at_end?

    start = @index + 1
    until current == ')'
      @index += 1
    end

    characters, times = @text[start..@index - 1].split('x').map(&:to_i)
    @index += 1

    return [characters, times, start-1, @index]
  end

  def at_end?
    @index >= @text.length
  end

  def current
    @text[@index]
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