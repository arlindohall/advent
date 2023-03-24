class Maze
  def initialize(maze, x, y, start)
    @maze = maze
    @x, @y = x, y
    @start = start
  end

  def solve_recursive
    @queue = neighbors_recursive(@start, 0)
    @distance = 1
    until @queue.empty?
      # debug_recursive
      puts "layers/#{@layers.size} visited/#{@layers.size} queue/#{@queue.size}"
      raise "Outside outermost layer" if @queue.any? { |pt, depth| depth < 0 }
      if @queue.any? { |pt, depth| visited_recursive?(loc: pt, depth: depth) }
        raise "Revisiting point"
      end
      @queue.each do |pt, depth|
        return @distance if depth == 0 && @maze[pt][:value] == "ZZ"
      end
      @queue.each { |pt, depth| visit_recursive(depth: depth, loc: pt) }
      @queue = @queue.flat_map { |loc, depth| steps_recursive(loc, depth) }.uniq
      @distance += 1
    end
  end

  def steps_recursive(loc, depth)
    case [@maze[loc][:type], @maze[loc][:location]]
    when %i[portal inner]
      neighbors_recursive(loc, depth) + portal_recursive(loc, depth)
    when %i[portal outer]
      neighbors_recursive(loc, depth) + portal_recursive(loc, depth)
    else
      neighbors_recursive(loc, depth)
    end
  end

  def neighbors_recursive(loc, depth)
    return [] if depth < 0
    x, y = loc
    [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]].filter do |x, y|
        @maze[[x, y]]
      end
      .reject { |x, y| visited_recursive?(loc: [x, y], depth: depth) }
      .map { |pt| [pt, depth] }
  end

  def visited_recursive?(loc:, depth:)
    @layers ||= {}
    @layers[[depth, loc]] == true
  end

  def visit_recursive(loc:, depth:)
    @layers[[depth, loc]] = true
  end

  def portal_recursive(loc, depth)
    return [] if depth < 0
    portals[@maze[loc][:value]]
      .reject { |portal| portal[:coords] == loc }
      .map { |portal| [portal[:coords], depth_change(loc, portal, depth)] }
      .filter { |portal, depth| depth >= 0 }
      .filter { |portal, depth| depth < 50 } # probably too deep
      .reject { |portal, depth| visited_recursive?(loc: portal, depth: depth) }
  end

  def depth_change(loc, portal, depth)
    source_portal = @maze[loc][:location]
    dest_portal = portal[:location]

    case [source_portal, dest_portal]
    when %i[inner inner]
      raise "Two inner portals"
    when %i[inner outer]
      depth + 1
    when %i[outer inner]
      depth - 1
    when %i[outer outer]
      raise "Two outer portals"
    end
  end

  def portals
    @portals ||=
      @maze
        .filter { |loc, point| point[:type] == :portal }
        .to_a
        .group_by { |loc, point| point[:value] }
        # .tap { |portals| portals.values.each { |v| p v.sort_by { |t| t.last[:location] } } }
        .transform_values do |points|
          points.map { |loc, point| {}.merge(point).merge({ coords: loc }) }
        end
  end

  def solve
    @queue = neighbors(@start)
    @distance = 1
    until @queue.empty?
      # _debug
      puts "visited/#{@visited.size} queue/#{@queue.size}"
      @queue.each { |pt| return @distance if @maze[pt][:value] == "ZZ" }
      @queue.each { |pt| @visited[pt] = true }
      @queue = @queue.flat_map { |loc| steps(loc) }.uniq
      @distance += 1
    end
  end

  def steps(loc)
    case @maze[loc][:type]
    when :space
      neighbors(loc)
    when :portal
      neighbors(loc) + portal(loc)
    end
  end

  def neighbors(loc)
    x, y = loc
    [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]].filter do |x, y|
      @maze[[x, y]] && !visited?([x, y])
    end
  end

  def portal(loc)
    @maze
      .keys
      .reject { |l| l == loc }
      .reject { |l| visited?(l) }
      .filter { |l| @maze[l][:value] == @maze[loc][:value] }
  end

  def visited?(pt)
    @visited ||= {}
    @visited[pt]
  end

  def debug_recursive
    print "\033[H"
    0.upto(@y) do |y|
      0.upto(@x) do |x|
        if visited_recursive?(loc: [x, y], depth: 0)
          print "x "
        elsif !@maze[[x, y]]
          print "  "
        else
          print @maze[[x, y]][:value]
        end
      end
      puts
    end
  end

  def _debug
    print "\033[H"
    0.upto(@y) do |y|
      0.upto(@x) do |x|
        if visited?([x, y])
          print "x "
        elsif !@maze[[x, y]]
          print "  "
        else
          print @maze[[x, y]][:value]
        end
      end
      puts
    end
  end

  class << self
    def parse(text)
      map = {}
      input = {}
      text.lines.each_with_index.map do |line, y|
        line.chomp.chars.each_with_index.map { |char, x| input[[x, y]] = char }
      end

      @xmax = input.keys.map(&:first).max
      @ymax = input.keys.map(&:last).max

      input.each do |(x, y), char|
        map[[x, y]] = translate(char, [x, y], input) if is_space?(char)
      end

      Maze.new(map, @xmax, @ymax, map.find { |_, v| v[:value] == "AA" }.first)
    end

    def is_space?(char)
      char == "."
    end

    def is_portal?(coords, input)
      names(coords, input).any?
    end

    def names(coords, input)
      x, y = coords
      names =
        [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]].filter do |(x, y)|
          input[[x, y]] =~ /[A-Z]/
        end

      names
    end

    def translate(char, coords, input)
      return portal(coords, input) if is_portal?(coords, input)
      return { type: :space, value: " ." }
    end

    def portal(coords, input)
      x, y = coords
      names_ = names(coords, input)

      {
        type: :portal,
        value: portal_name([x, y], names_.first, input),
        location: inner_outer(x, y)
      }
    end

    def inner_outer(x, y)
      return :outer if x == 2
      return :outer if y == 2
      return :outer if x == @xmax - 2
      return :outer if y == @ymax - 2

      return :inner
    end

    def portal_name(coords, name, input)
      [input[name], input[next_letter(coords, name)]].sort.join
    end

    def next_letter(portal, first_letter)
      px, py = portal
      lx, ly = first_letter

      [lx + (lx - px), ly + (ly - py)]
    end
  end
end

begin
  dir = File.dirname(__FILE__)
  @example1 = File.read("#{dir.to_s}/example1.txt")
  @example2 = File.read("#{dir.to_s}/example2.txt")
  @example3 = File.read("#{dir.to_s}/example3.txt")
  @input = File.read("#{dir.to_s}/input.txt")
end

def test
  [Maze.parse(@example1).solve, 23, Maze.parse(@example2).solve, 58].each_slice(
    2
  ) do |input, expected|
    raise "Expected #{expected} but got #{input}" unless input == expected
  end

  actual = Maze.parse(@example3).solve_recursive
  raise "Expected 396 but got #{actual}" unless actual == 396

  :success
end

def solve
  [Maze.parse(@input).solve, Maze.parse(@input).solve_recursive]
end
