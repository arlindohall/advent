def solve =
  Assignments
    .parse(read_input)
    .then { |it| [it.fully_contained.count, it.overlap.count] }

class Assignments
  shape :pairs

  def self.parse(text)
    text
      .split
      .map { |line| line.split(",") }
      .sub_map { |assm| assm.split("-").map(&:to_i) }
      .sub_map { |start, stop| Assignment.new(start:, stop:) }
      .then { |it| new(pairs: it) }
  end

  def fully_contained
    pairs.filter { |p1, p2| p1.include?(p2) || p2.include?(p1) }
  end

  def overlap
    pairs.filter { |p1, p2| p1.overlap?(p2) || p2.overlap?(p1) }
  end

  class Assignment
    shape :start, :stop

    def include?(other)
      range.include?(other.start) && range.include?(other.stop)
    end

    def overlap?(other)
      range.include?(other.start) || range.include?(other.stop)
    end

    def range
      start..stop
    end
  end
end
