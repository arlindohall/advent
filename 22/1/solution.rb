def solve =
  CalorieTracker.parse(read_input).then { |it| [it.max, it.top_three] }

class CalorieTracker
  shape :elves

  def max
    elves.map(&:sum).max
  end

  def top_three
    elves.map(&:sum).sort.reverse.take(3).sum
  end

  def self.parse(text)
    text.split("\n\n").map(&:split).sub_map(&:to_i).then { |it| new(elves: it) }
  end
end
