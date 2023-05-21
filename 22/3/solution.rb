def solve =
  Rucksacks
    .parse(read_input)
    .then { |it| [it.shared_priority, it.group_priority] }

class Rucksacks
  shape :sacks

  def self.parse(text)
    new(sacks: text.split.map { |s| Rucksack.new(contents: s) })
  end

  def group_priority
    groups.map { |group| priority(group) }.sum
  end

  def groups
    sacks
      .each_slice(3)
      .map do |group|
        group.map(&:contents).map(&:chars).map(&:to_set).reduce(&:&)
      end
      .map(&:only!)
  end

  def shared_priority
    shared.map { |item| priority(item) }.sum
  end

  def shared
    sacks.map(&:shared).map(&:only!)
  end

  def priority(item)
    case item
    when "a".."z"
      item.ord - "a".ord + 1
    when "A".."Z"
      item.ord - "A".ord + 27
    end
  end
end

class Rucksack
  shape :contents

  memoize def compartments
    halfway = contents.size / 2
    [contents[0...halfway], contents[halfway..]].map(&:chars).map(&:to_set)
  end

  def shared
    compartments[0] & compartments[1]
  end
end
