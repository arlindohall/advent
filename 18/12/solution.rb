
Rule = Struct.new(:source, :result)

class Cave
  attr_reader :plants, :rules

  def initialize(plants, rules)
    @plants = plants
    @rules = rules
  end

  def self.of(text)
    plants = /initial state: (\S+)/.match(text)
      .captures
      .first
      .chars
      .each_with_index
      .map { |pl, idx| pl == '#' ? idx : nil }
      .compact

    rules = text.lines
      .map { |line| /(\S+) => (\S)/.match(line) }
      .compact
      .map { |match| match.captures }
      .map { |source, result| [source.chars, result] }
      .map { |source, result| [source, Rule.new(source, result)] }
      .to_h

    new(plants, rules)
  end

  # From reading online, there's an arithmetic pattern after a certain number of gens
  # 100 => 8154
  # 100 + N => 8154 + N * 57
  # M := 100 + N
  # M => 8154 + (M - 100) * 57
  def left_after(generations)
    return (8154 + (generations - 100) * 57) if generations > 1000

    cave = self
    generations.times { cave = Cave.new(cave.next_generation, @rules) }

    cave.plants.sum
  end

  def next_generation
    results.filter { |idx, result| result == '#' }
      .map(&:first)
  end

  def results
    sections.map { |idx, section| [idx, @rules[section]&.result || '.'] }
  end

  def sections
    (@plants.min-3).upto(@plants.max+3).map { |idx| [idx, section(idx)] }
  end

  def section(index)
    (index-2).upto(index+2).map { |i| @plants.include?(i) ? '#' : '.'}
  end
end

@example = <<-text
initial state: #..#.#..##......###...###

...## => #
..#.. => #
.#... => #
.#.#. => #
.#.## => #
.##.. => #
.#### => #
#.#.# => #
#.### => #
##.#. => #
##.## => #
###.. => #
###.# => #
####. => #
text

@input = <<-text
initial state: #.#####.#.#.####.####.#.#...#.......##..##.#.#.#.###..#.....#.####..#.#######.#....####.#....##....#

##.## => .
#.#.. => .
..... => .
##..# => #
###.. => #
.##.# => .
..#.. => #
##.#. => #
.##.. => .
#..#. => .
###.# => #
.#### => #
.#.## => .
#.##. => #
.###. => #
##### => .
..##. => .
#.#.# => .
...#. => #
..### => .
.#.#. => #
.#... => #
##... => #
.#..# => #
#.### => #
#..## => #
....# => .
####. => .
#...# => #
#.... => .
...## => .
..#.# => #
text