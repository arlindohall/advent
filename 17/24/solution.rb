Component = Struct.new(:left, :right)

# Components go from left to right
class Component
  def flip
    Component.new(right, left)
  end

  def orient(n)
    if self.left == n
      self
    else
      flip
    end
  end

  def to_s
    "#{left}/#{right}"
  end

  def inspect
    "#{left}/#{right}"
  end
end

class Bridge
  attr_reader :components, :bin
  def initialize(components, bin)
    @components = components
    @bin = bin
  end

  def strength
    @components.map { |c| c.left + c.right }.sum
  end

  def extensions
    @bin
      .filter { |c| can_connect?(c) }
      .map { |c| Bridge.new(@components + [c.orient(last)], @bin - [c]) }
  end

  def can_connect?(c)
    c.values.any? { |v| v == last }
  end

  def last
    @components.last.right
  end
end

class Builder
  def initialize(components)
    @components = components
  end

  def self.of(text)
    new(
      text
        .split("\n")
        .map { |l| l.split("/").map(&:to_i) }
        .map { |l| Component.new(l[0], l[1]) }
        .to_set
    )
  end

  def solve
    [strongest_bridge.strength, @longest.max_by(&:strength).strength]
  end

  def strongest_bridge
    @queue = first_bridges
    @strongest = Bridge.new([], []) # Empty but we won't use it except to compare once
    @longest = [@strongest]

    while @queue.any?
      dequeue
      _debug(@strongest)
      compare
      compare_length
      build_bridges
    end

    @strongest
  end

  def _debug(winner)
    if @queue.length % 1000 == 0
      p [@queue.length, winner.strength, @bridge.components.length]
    end
  end

  def all
    bridges = first_bridges
    all_bridges = bridges.dup
    15.times do
      bridges = bridges.flat_map(&:extensions)
      all_bridges += bridges
    end
    all_bridges
  end

  def extend(n = 1)
    bridges = first_bridges
    n.times { bridges = bridges.flat_map(&:extensions) }
    bridges
  end

  def first_bridges
    starting_components.map do |c|
      Bridge.new([c.orient(0)], @components - Set[c])
    end
  end

  def dequeue
    @bridge = @queue.shift
  end

  def compare
    @strongest = @bridge if @bridge.strength > @strongest.strength
  end

  def compare_length
    if @bridge.components.length > @longest.first.components.length
      @longest = [@bridge]
    elsif @bridge.components.length == @longest.first.components.length
      @longest << @bridge
    end
  end

  def build_bridges
    @bridge.extensions.each { |e| @queue << e }
  end

  def starting_components
    @components.filter { |c| c.values.any?(&:zero?) }
  end
end

@example = <<-ex.strip
0/2
2/2
2/3
3/4
3/5
0/1
10/1
9/10
ex

# between 998 & 1917
@input = <<-comp.strip
50/41
19/43
17/50
32/32
22/44
9/39
49/49
50/39
49/10
37/28
33/44
14/14
14/40
8/40
10/25
38/26
23/6
4/16
49/25
6/39
0/50
19/36
37/37
42/26
17/0
24/4
0/36
6/9
41/3
13/3
49/21
19/34
16/46
22/33
11/6
22/26
16/40
27/21
31/46
13/2
24/7
37/45
49/2
32/11
3/10
32/49
36/21
47/47
43/43
27/19
14/22
13/43
29/0
33/36
2/6
comp
