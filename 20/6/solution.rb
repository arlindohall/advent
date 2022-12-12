
class Person < Struct.new(:answers)
  def set
    answers.to_set
  end
end

class Group < Struct.new(:people)
  def uniq
    people.map(&:set).reduce(&:+)
  end

  def shared
    people.map(&:set).reduce(&:&)
  end

  def self.parse(lines)
    new(
      lines.split("\n").map { Person.new(_1.chars) }
    )
  end
end

class CollectedAnswers < Struct.new(:groups)
  def sum_counts
    [
      groups.map(&:uniq).map(&:size).sum,
      groups.map(&:shared).map(&:size).sum,
    ]
  end

  def self.parse(input)
    new(
      input.strip.split("\n\n").map { ::Group.parse(_1) }
    )
  end
end