
class BoardingPass < Struct.new(:text)
  def seat_id
    row * 8 + column
  end

  def row
    binary_row.join.to_i(2)
  end

  def column
    binary_column.join.to_i(2)
  end

  def binary_row
    text.chars.take(7).map { _1 == 'F' ? '0' : '1' }
  end

  def binary_column
    text.chars.drop(7).map { _1 == 'L' ? '0' : '1' }
  end
end

class Scanner < Struct.new(:passes)
  def missing
    set = ids.to_set
    ids.min.upto(ids.max) do |id|
      return id unless set.include?(id)
    end

    raise "Not found"
  end

  def largest_id
    ids.max
  end

  def ids
    @ids ||= passes.strip
      .split("\n")
      .map { |ps| BoardingPass.new(ps) }
      .map(&:seat_id)
      .sort
  end
end

def solve
  [Scanner.new(read_input).largest_id, Scanner.new(read_input).missing]
end