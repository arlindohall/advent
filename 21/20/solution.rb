def solve = TrenchMap.parse(read_input).then { |tm| [tm.twice, tm.fifty] }

# I got help from...
# https://www.ericburden.work/blog/2021/12/30/advent-of-code-2021-day-20/
#
# Basically, you want to track either lit or unlit because the 0th and 511th
# are the result of '.........' and '##########' respectively.
#
# And in the example, they map all unlit to unlit, but in the input they map
# the oposite, so you need to toggle which one you're tracking

class TrenchMap
  attr_reader :map, :enhancement, :tracking, :toggle
  def initialize(**params)
    @map = params[:map]
    @enhancement = params[:enhancement]
    @tracking = params[:tracking]
    @toggle = params[:toggle]
  end

  def lit
    raise "infinite lit" unless tracking == "#"
    map.size
  end

  def unlit
    raise "infinite unlit" unless tracking == "."
    map.size
  end

  def twice
    apply.apply.lit
  end

  def fifty
    tm = self
    50.times do |i|
      tm = tm.apply
      # print "#{i}, "
    end
    puts "done!"

    tm.lit
  end

  def apply
    self.class.new(
      map: update_map,
      tracking: toggle ? non_tracking : tracking,
      enhancement:,
      toggle:
    )
  end

  def non_tracking
    tracking == "#" ? "." : "#"
  end

  def update_map
    possible_squares
      .filter do |x, y|
        toggle ? output(x, y) == non_tracking : output(x, y) == tracking
      end
      .to_set
  end

  def bounds
    @bounds ||= map.to_a.flatten.minmax
    (@bounds.first)..(@bounds.last)
  end

  def possible_squares
    map.map { |x, y| window(x, y) }.flatten(1).to_set
  end

  def window(x, y)
    (y - 1).upto(y + 1).flat_map { |y| (x - 1).upto(x + 1).map { |x| [x, y] } }
  end

  def enhancement_index(x, y)
    index = 0
    window(x, y).each do |x, y|
      index = index << 1
      index += 1 if lit?(x, y)
    end

    index
  end

  def output(x, y)
    enhancement[enhancement_index(x, y)]
  end

  def lit?(x, y)
    case tracking
    when "#"
      map.include?([x, y])
    when "."
      map.exclude?([x, y])
    else
      raise "wtf"
    end
  end

  def in_bounds?(x, y)
    bounds.include?(x) && bounds.include?(y)
  end

  def debug!
    bounds.each do |y|
      bounds.each do |x|
        if lit?(x, y)
          print "#".darken_squares
        else
          print " "
        end
      end
      puts
    end
    puts
  end

  def self.parse(text)
    new(
      enhancement: text.split("\n\n").first.chars,
      map:
        text
          .split("\n\n")
          .second
          .split
          .each_with_index
          .flat_map do |row, y|
            row.chars.each_with_index.map { |col, x| [x, y] if col == "#" }
          end
          .compact
          .to_set,
      tracking: "#",
      toggle: text[0] == "#"
    )
  end
end
