def solve(input = read_input) =
  AshPatterns.new(input).then { |ap| [ap.note_summary] }

class AshPatterns
  def initialize(text)
    @text = text
  end

  def note_summary
    lines_of_refelction.map { |line| line.score }.sum
  end

  def lines_of_refelction
    reflected_images.map { |image| image.line_of_reflection }
  end

  def reflected_images
    @text.split("\n\n").map { |blob| ReflectedImage.new(blob) }
  end
end

class ReflectedImage
  def initialize(blob)
    @blob = blob
  end

  def line_of_reflection
    column_reflection || row_reflection
  end

  def column_reflection
    ref = column_divisions.find { |column| column.reflected_over? }

    ColumnReflection.new(ref) if ref
  end

  def row_reflection
    ref = row_divisions.find { |row| row.reflected_over? }

    RowReflection.new(ref) if ref
  end

  def column_divisions
    row_divisions(pattern.transpose)
  end

  def row_divisions(pattern = self.pattern)
    pattern
      .each_index
      .drop(1)
      .map { |index| DivisionBeforeIndex.new(pattern, index) }
  end

  def pattern
    @blob.split("\n").map { |line| line.chars }
  end
end

class DivisionBeforeIndex
  def initialize(pattern, index)
    @pattern = pattern
    @index = index
  end

  def groups_before_index
    @index
  end

  memoize def reflected_over?
    @distance = 0

    loop do
      return true if bottom_row.nil? || top_row.nil?
      return false if top_row != bottom_row

      @distance += 1
    end
  end

  def top_row
    index = @index - @distance - 1
    @pattern[index] if index >= 0
  end

  def bottom_row
    index = @index + @distance
    @pattern[index] if index < @pattern.length
  end
end

class ColumnReflection < Struct.new(:division)
  def score = division.groups_before_index
end

class RowReflection < Struct.new(:division)
  def score = 100 * division.groups_before_index
end
