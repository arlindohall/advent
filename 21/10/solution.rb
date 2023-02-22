def solve =
  NavigationSystem
    .parse(read_input)
    .then { |it| [it.syntax_score, it.middle_score] }

class NavigationSystem
  attr_reader :lines
  def initialize(lines)
    @lines = lines
  end

  def syntax_score
    lines.filter(&:corrupted?).map(&:syntax_score).sum
  end

  def middle_score
    lines.filter(&:incomplete?).map(&:autocomplete_score).median
  end

  def self.parse(text)
    new(text.split.map { |ln| Line.new(ln).tap(&:parse) })
  end

  class Line
    attr_reader :text
    def initialize(text)
      @text = text
    end

    attr_reader :index
    def parse
      @index ||= 0
      return @incomplete = true if index >= text.size && seen.any?
      return if index >= text.size && seen.empty?

      if opening(current)
        seen << current
        @index += 1
        return parse
      end

      if match(top, current)
        seen.pop
        @index += 1
        return parse
      end

      return @corrupted = true if closing(current)

      seen << current
    end

    def seen
      @seen ||= []
    end

    def top
      seen.last
    end

    def current
      text[index]
    end

    BRACKETS = { "(" => ")", "[" => "]", "{" => "}", "<" => ">" }
    def match(open, close)
      BRACKETS[open] == close
    end

    def closing(char)
      BRACKETS.values.include?(char)
    end

    def opening(char)
      BRACKETS.keys.include?(char)
    end

    def incomplete?
      !!@incomplete
    end

    def corrupted?
      !!@corrupted
    end

    SYNTAX_SCORES = { ")" => 3, "]" => 57, "}" => 1197, ">" => 25_137 }
    def syntax_score
      SYNTAX_SCORES[current]
    end

    MIDDLE_SCORES = { ")" => 1, "]" => 2, "}" => 3, ">" => 4 }
    def autocomplete_score
      seen
        .reverse
        .map { |char| MIDDLE_SCORES[BRACKETS[char]] }
        .reduce(0) { |acc, ch| acc * 5 + ch }
    end
  end
end
