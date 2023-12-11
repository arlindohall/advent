$_debug = false

def solve(input = read_input) =
  WastelandMap.new(input).then { |wm| [wm.steps, wm.ghost_steps] }

class WastelandMap
  def initialize(text)
    @text = text
  end

  def steps
    @location = "AAA"
    @steps = 0
    follow_instructions
  end

  def ghost_steps
    GhostMap.new(map, instructions).steps
  end

  def follow_instructions
    instructions.each do |inst|
      _debug("following one", inst:, steps: @steps)
      @steps += 1
      @location = map[@location]
      @location = inst == "L" ? @location.left : @location.right
      return @steps if @location == "ZZZ"
    end
  end

  def instructions
    @text.split("\n\n").first.chars.cycle
  end

  memoize def map
    @text
      .split("\n\n")
      .second
      .split("\n")
      .map { |line| Node.new(line) }
      .hash_by { |node| node.name }
  end
end

class Node
  def initialize(text)
    @text = text
  end

  def name
    @text.split(" = ").first
  end

  def left
    children.first
  end

  def right
    children.second
  end

  def children
    @text.split(" = ").second.scan(/\w{3}/)
  end
end

class GhostMap
  def initialize(map, instructions)
    @map = map
    @instructions = instructions
  end

  def steps
    starting_points.map { |sp| follow_instructions(sp) }.reduce(&:lcm)
  end

  def follow_instructions(starting_point)
    @location = starting_point
    @steps = 0
    @instructions.each do |inst|
      follow_one(inst)
      return @steps if @location =~ /..Z/
    end
  end

  def follow_one(inst)
    @steps += 1
    @location = @map[@location]
    @location = inst == "L" ? @location.left : @location.right
  end

  def starting_points
    @map.keys.select { |k| k =~ /..A/ }
  end
end
