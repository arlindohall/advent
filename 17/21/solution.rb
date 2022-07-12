
class Rule
  attr_reader :pattern, :result
  def initialize(pattern, result)
    @pattern = pattern
    @result = result
  end

  def self.of(text)
    pattern, result = text.split(' => ').map{|entity| entity.split("/").map(&:chars)}
    new(pattern, result)
  end

  def sub_results
    return @sub_results if @sub_results
    if @pattern.size == 2
      @sub_results = @result.map(&:join).join
    else
      @sub_results = @result.each_slice(2)
        .flat_map { |rows|
          rows.map{ |row|
            row.each_slice(2).to_a
          }.reduce(&:zip)
           .map{|pair| pair.flatten.join }
        }.to_a
    end
  end

  <<-examples
  rotations
  01  20  32  13
  23  31  10  02

  rotations flipped horizontally -> actually same as first row transposed, shifted once
  10  02  23  31
  32  13  01  20

  rotations flipped vertically -> all repeated, not necessary
  23  31  10  02
  01  20  32  13

  I don't think this holds for 3D, though
  examples
  def patterns
    rotations.flat_map{|r| flip(r)}.uniq
  end

  def flip(rotation)
    [rotation, rotation.reverse, rotation.map{|row| row.reverse}]
  end

  def show_rotations
    # for debugging
    rotations.each{ |r|
      puts r.map(&:join).join("\n") + "\n\n"
    }
  end

  def rotations
    if @pattern.size == 2
      n2_rotations
    else
      n3_rotations
    end
  end

  def n2_rotations
    edges = [@pattern.first, @pattern.last.reverse].flatten
    4.times.map{|i|
      edges.rotate(i)
    }.map{|configuration|
      first, second = configuration.each_slice(2).to_a
      [first, second.reverse]
    }
  end

  def n3_rotations
    rotated_edges.map{|configuration|
      first = configuration.take(3)
      last = configuration[4..6].reverse
      middle = [configuration.last, @pattern[1][1], configuration[3]]
      [first, middle, last]
    }
  end

  def rotated_edges
    4.times.map{|i|
      edges.rotate(i*2)
    }
  end

  def edges
    [@pattern.first, @pattern[1].last, @pattern.last.reverse, @pattern[1].first].flatten
  end

end

class Puzzle
  attr_reader :grid, :rules
  def initialize(grid, rules)
    @grid = grid
    @rules = rules
  end

  def self.of(string, rulebook)
    new(
      string.strip.split("\n").map(&:chars),
      rulebook.strip.split("\n").map { |line| Rule.of(line) }
        .flat_map{|rule| rule.patterns.map{|pat| [pat.flatten.join, rule]} }
        .to_h
    )
  end

  def solve
    [rounds(5), rounds(18)].map(&:count_on)
  end

  def show
    puts @grid.map(&:join).join("\n")
  end

  def count_on
    @grid.join.count('#')
  end

  def rounds(n)
    puzzle = self
    n.times { puzzle = puzzle.enhance }
    puzzle
  end

  def enhance
    Puzzle.new(
      update_grid,
      @rules
    )
  end

  def update_grid
    if @grid.size.even?
      join(update(2))
    else
      join(update(3))
    end
  end

  def update(n)
    partition_grid(n)
      .map(&:join)
      .map{|sub| @rules[sub].result }
  end

  def partition_grid(n)
    @partitioned ||= @grid.each_slice(n)
      .flat_map {|pair_of_rows|
        pair_of_rows.map { |row|
          row.each_slice(n).to_a
        }.reduce(&:zip)
      }
  end

  def join(updated)
    n = Math.sqrt(updated.size)
    updated.each_slice(n).flat_map{|row| join_row(row)}
  end

  def join_row(row)
    row.first.each_index.map { |index|
      row.map{|r| r[index]}.flatten
    }
  end
end

@pattern = <<-pattern.strip
.#.
..#
###
pattern

@example = <<-rules.strip
../.# => ##./#../...
.#./..#/### => #..#/..../..../#..#
rules

@input = <<-rules.strip
../.. => ###/#../.#.
#./.. => ##./.#./...
##/.. => ..#/.#./#.#
.#/#. => ..#/.#./..#
##/#. => .../.##/##.
##/## => ###/#../#..
.../.../... => .#../.#../#..#/##..
#../.../... => ####/####/.###/####
.#./.../... => ####/..../#.#./.#.#
##./.../... => ..##/###./...#/##.#
#.#/.../... => .#../#..#/.#../#.#.
###/.../... => #.##/..##/##.#/..##
.#./#../... => .##./#..#/..../....
##./#../... => ##../.#../...#/####
..#/#../... => ##../###./...#/.#.#
#.#/#../... => ####/#.../..../##..
.##/#../... => #..#/..##/#..#/....
###/#../... => #.##/####/..#./#.#.
.../.#./... => #.##/.#.#/#.../...#
#../.#./... => .###/##.#/..../###.
.#./.#./... => ..#./.#../..../##..
##./.#./... => ##../...#/..../....
#.#/.#./... => ####/.#../..#./.###
###/.#./... => ..#./.###/##../.##.
.#./##./... => ###./#.#./.###/.##.
##./##./... => ...#/.#../.#../####
..#/##./... => ..#./#.../##../###.
#.#/##./... => #.../..../.#.#/.###
.##/##./... => #.#./.#../####/.###
###/##./... => .#.#/#.#./##../#...
.../#.#/... => #.##/##.#/..../#.#.
#../#.#/... => ##../#.##/###./###.
.#./#.#/... => ##../.#../#.##/###.
##./#.#/... => ##../##../..#./..#.
#.#/#.#/... => #.../.##./.###/###.
###/#.#/... => ##.#/##../.##./#...
.../###/... => ...#/####/..../#..#
#../###/... => ##.#/##.#/.##./#.#.
.#./###/... => .#../#.../.#.#/##.#
##./###/... => ##.#/#.#./#.../.#..
#.#/###/... => ..../#.../####/.#..
###/###/... => .#../#..#/.#../.#..
..#/.../#.. => .#.#/#.../..##/...#
#.#/.../#.. => ####/####/###./...#
.##/.../#.. => ####/.###/##.#/##..
###/.../#.. => ..##/..../...#/#.#.
.##/#../#.. => ###./..#./##.#/##.#
###/#../#.. => ##.#/...#/.##./.###
..#/.#./#.. => #.#./#.#./...#/#.#.
#.#/.#./#.. => ###./.#.#/#.#./.#..
.##/.#./#.. => #.#./.##./.###/#.#.
###/.#./#.. => #.../#.../#.#./.###
.##/##./#.. => .#.#/.##./..#./##..
###/##./#.. => .###/.##./#.##/..##
#../..#/#.. => #.#./#..#/###./.##.
.#./..#/#.. => ###./.###/...#/..##
##./..#/#.. => ###./##../####/.#.#
#.#/..#/#.. => ..#./.#../.##./.#..
.##/..#/#.. => ##.#/###./.##./#...
###/..#/#.. => ...#/..##/##.#/##.#
#../#.#/#.. => #.../.##./.#.#/.###
.#./#.#/#.. => #.##/...#/####/###.
##./#.#/#.. => .#../#.../.###/....
..#/#.#/#.. => ####/###./.#.#/#...
#.#/#.#/#.. => ###./..##/...#/#.##
.##/#.#/#.. => ##.#/..#./..##/.#.#
###/#.#/#.. => #.#./..../##../.###
#../.##/#.. => #..#/###./.#.#/##.#
.#./.##/#.. => #.../.###/.##./.###
##./.##/#.. => .#../###./.#../##.#
#.#/.##/#.. => .#../#.#./.#../#.##
.##/.##/#.. => ##../###./.#.#/.###
###/.##/#.. => ..##/...#/#.../.#..
#../###/#.. => #.##/#..#/####/###.
.#./###/#.. => .###/.#.#/#.#./..#.
##./###/#.. => ####/#.#./..##/#.##
..#/###/#.. => .###/##.#/.##./#.#.
#.#/###/#.. => #.##/###./.###/....
.##/###/#.. => #.##/..../.#../####
###/###/#.. => ##.#/###./.#../...#
.#./#.#/.#. => ..#./##.#/.#../###.
##./#.#/.#. => ..##/###./..#./.#.#
#.#/#.#/.#. => .#../..##/.#.#/.#.#
###/#.#/.#. => ##../#..#/.#../..#.
.#./###/.#. => #.../#..#/.#.#/....
##./###/.#. => ..../..##/..#./####
#.#/###/.#. => ..##/##.#/.###/...#
###/###/.#. => ##.#/#.##/..#./#.#.
#.#/..#/##. => #.../####/#.##/.###
###/..#/##. => ###./...#/.#.#/#..#
.##/#.#/##. => ..../.#.#/##.#/..##
###/#.#/##. => ###./.#../.#.#/###.
#.#/.##/##. => ###./.#../.#../.#.#
###/.##/##. => .##./..../..../#.##
.##/###/##. => ####/##../.###/##.#
###/###/##. => #..#/#.##/#.##/.#..
#.#/.../#.# => ####/#.#./#..#/.##.
###/.../#.# => .#../.#.#/.#../.#.#
###/#../#.# => ..#./..#./.###/#...
#.#/.#./#.# => #.#./..../.##./####
###/.#./#.# => #.../..##/.##./..#.
###/##./#.# => .#.#/##../#.#./..#.
#.#/#.#/#.# => #.##/#.##/#.##/..##
###/#.#/#.# => .###/#.#./.##./..##
#.#/###/#.# => ...#/#.#./..#./#..#
###/###/#.# => #.../#..#/#..#/.##.
###/#.#/### => .#.#/..##/##.#/#...
###/###/### => .###/#.#./#.../#...
rules