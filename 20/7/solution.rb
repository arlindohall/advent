
class Bag < Struct.new(:description, :contains)
  def contains_shiny_gold?
    contains.keys.any?(&:is_shiny_gold?) ||
      contains.keys.any?(&:contains_shiny_gold?)
  end

  def is_shiny_gold?
    description == "shiny gold"
  end

  def count_contents
    contains.map { |bag, count| count * (1 + bag.count_contents) }.sum
  end
end

class Processor < Struct.new(:text)
  def count_shiny_gold
    loaded
    bags.values.count(&:contains_shiny_gold?)
  end

  def shiny_gold_contents
    loaded
    bags["shiny gold"].count_contents
  end

  def loaded
    return if @loaded
    @loaded = true
    text.lines.each { parse_bag(_1) }
  end

  def parse_bag(line)
    name, contains_part = line.match(/(.*) bags contain (.*) bag(s)?./).captures.take(2)
    bags = contains_part.split(/ bag(s)?, /)
      .map { [lookup_bag(_1.split(" ").drop(1).join(" ")), _1.to_i] }
      .to_h

    lookup_bag(name).tap do |bag|
      bag.contains.merge!(bags)
    end
  end

  def lookup_bag(description)
    bags[description] ||= Bag.new(description, {})
  end

  def bags
    @bags ||= {}
  end
end

def solve
  [
    Processor.new(read_input).count_shiny_gold,
    Processor.new(read_input).shiny_gold_contents,
  ]
end