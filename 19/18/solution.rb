$debug = false

class Tunnels
  attr_reader :steps, :location, :keys_held

  def initialize(graph, location, steps = 0, keys_held = [])
    @graph = graph
    @location = location
    @steps = steps
    @keys_held = keys_held
  end

  def dup
    Tunnels.new(
      @graph,
      @location,
      @steps,
      @keys_held.dup,
    )
  end

  def travel_to(key, distance)
    # raise "Traveling to key we already have" if already_has_key?(key)
    already_has_key?(key) ?
      Tunnels.new(
        @graph,
        key,
        @steps + distance,
        @keys_held,
      ) :
      Tunnels.new(
        @graph,
        key,
        @steps + distance,
        key =~ /[a-z]/ ? @keys_held + [key] : @keys_held,
      )
  end

  def find_all_keys
    @location = ?@
    @search_queue = [dup]
    @search_count = 0

    until @search_queue.empty?
      @search_count += 1
      @locus = @search_queue.shift
      puts "Starting new queue round with locus=#{@locus.location}, " \
        "fastest=#{@fastest_path}, " \
        "queue=#{@search_queue.size}, " \
        "visited/#{@visited&.size}, " \
        "search_count=#{@search_count}" if @search_count % 1000 == 0
      enqueue_paths
    end

    @fastest_path
  end

  def enqueue_paths
    (print "-Neighbors: " ; p @locus.neighbors) if $debug
    @locus.neighbors.each do |neighbor, distance|
      visit(neighbor, distance)
    end
  end

  def neighbors
    @graph.neighbors(@location)
  end

  def visit(neighbor, distance)
    return unless @locus.can_access?(neighbor)
    return if visited?(neighbor, @locus.keys_held)

    move = @locus.travel_to(neighbor, @steps + distance)

    return if check_finished(move)

    (print "-Adding to search queue: " ; puts move.debug) if $debug
    @search_queue << move
  end

  def check_finished(move)
    return false unless move.finished?

    @fastest_path ||= move.steps
    @fastest_path = [move.steps, @fastest_path].min
  end

  def visited?(neighbor, keys_held)
    # puts "--Checking if have key #{neighbor}"
    # return true if @locus.already_has_key?(neighbor)

    puts "--Checking if visited: #{neighbor}, #{@locus.steps}, #{keys_held}" if $debug
    @visited ||= {}
    return true if @visited[[neighbor, keys_held.sort]] &&
      @visited[[neighbor, keys_held.sort]] <= @locus.steps

    @visited[[neighbor, keys_held.sort]] = @locus.steps

    false
  end

  def can_access?(door)
    return true unless door =~ /[A-Z]/
    @keys_held.include?(door.downcase)
  end

  def already_has_key?(key)
    @keys_held.include?(key)
  end

  def key?(name)
    name =~ /[a-z]/
  end

  def entrance?(name)
    name == ?@
  end

  def door?(name)
    name =~ /[A-Z]/
  end

  def finished?
    @keys_held.sort == @graph.keys.sort
  end

  def debug
    "Tunnels(location=#{@location}, steps=#{@steps}, keys_held=#{@keys_held})"
  end

  class << self
    def parse(text)
      graphify(*map_properties(text))
    end

    def map_properties(text)
      [
        text.split("\n")
          .each_with_index
          .flat_map do |line, y|
            line.split('')
              .each_with_index
              .map { |ch, x| [[x,y], ch] }
          end
          .to_h,
        text.split("\n").first.size,
        text.split("\n").size
      ]
    end

    def graphify(map, x, y)
      new(graph_from(map, x, y), ?@)
    end

    def graph_from(map, x, y)
      parser_from(map, x, y).parse
    end

    def parser_from(map, x, y)
      Graph::Parser.new(map, x, y)
    end
  end
end

class Graph
  def initialize(nodes)
    @nodes = nodes
  end

  def keys
    @keys ||= @nodes.keys.filter { |key| key =~ /[a-z]/ }
  end

  def neighbors(point)
    @nodes[point].neighbors
  end

  Node = Struct.new(:name, :location, :neighbors)
  class Node
  end

  class Parser
    def initialize(map, x, y)
      @map = map
      @x, @y = x, y
    end

    def dup
      Parser.new(@map.dup, @x, @y)
    end

    def parse
      # puts "Searching #{nodes.size} nodes"
      nodes.keys.each { |name| nodes[name].neighbors = dup.fill_neighbors(name) }
      Graph.new(nodes)
    end

    def nodes
      @nodes ||= @map.each_with_object({}) do |(location, ch), nodes|
        raise "Duplicate node #{ch} at #{location}" if nodes[ch]
        nodes[ch] = Node.new(ch, location) if ch =~ /[A-Za-z@]/
      end
    end

    def node(name)
      nodes[name]
    end

    def fill_neighbors(key)
      raise "Unknown key #{key} value=#{node(key)} map=#{@map[node(key).location]}" unless node(key)
      initialize_search(key)
      # puts "Searching for #{@starting_point.name}"

      until @search_queue.empty?
        update_search_queue
        @distance += 1
      end

      # p @found_neighbors.map(&:first).uniq
      # p @found_neighbors.map(&:first)

      raise "Expected unique paths to neighbors" unless @found_neighbors.map(&:first).uniq.size == @found_neighbors.size
      @found_neighbors
    end

    def initialize_search(key)
      @found_neighbors = []
      @starting_point = node(key)
      @distance = 1
      @search_queue = neighbors(@starting_point.location)
      @map[@starting_point.location] = ?#
    end

    def update_search_queue
      debug

      @search_queue = @search_queue.map do |location|
        visit(location)
      end
      .compact
      .flat_map { |location| neighbors(location) }
    end

    def visit(location)
      if @map[location] =~ /[A-Za-z@]/
        @found_neighbors << [@map[location], @distance]
        return
      end

      location
    ensure
      @map[location] = ?#
    end

    def neighbors(location)
      x, y = location
      [
        [x-1, y],
        [x+1, y],
        [x, y-1],
        [x, y+1],
      ].filter { |loc| @map[loc] && @map[loc] != ?# }
    end

    def debug
      return unless $debug
      print "\033[H"
      0.upto(@y) do |y|
        0.upto(@x) do |x|
          print @map[[x,y]] || ' '
        end
        puts
      end
      puts @search_queue.size
    end
  end
end

def test
  [
    @example1, 8,
    @example2, 86,
    @example3, 132,
    @example4, 136,
    @example5, 81,
  ].each_slice(2) do |input, expected|
    actual = Tunnels.parse(input).find_all_keys
    raise "Expected #{expected} got #{actual}" unless actual == expected
  end

  :success
end

def solve
  Tunnels.parse(@input).find_all_keys
end

@example1 = <<-map.strip
#########
#b.A.@.a#
#########
map

@example2 = <<-map.strip
########################
#f.D.E.e.C.b.A.@.a.B.c.#
######################.#
#d.....................#
########################
map

@example3 = <<-map.strip
########################
#...............b.C.D.f#
#.######################
#.....@.a.B.c.d.A.e.F.g#
########################
map

@example4 = <<-map.strip
#################
#i.G..c...e..H.p#
########.########
#j.A..b...f..D.o#
########@########
#k.E..a...g..B.n#
########.########
#l.F..d...h..C.m#
#################
map

@example5 = <<-map.strip
########################
#@..............ac.GI.b#
###d#e#f################
###A#B#C################
###g#h#i################
########################
map

@input = <<-map.strip
#################################################################################
#...#.....#......c....#...#.Q.......#...#f#a....#..j..........#...............#.#
#.#.#.#.###.#######.#.#.#.#.###.###.#.#.#.#.###.#.#######.###.#.#.###########.#.#
#.#.#v#.....#.....#.#...#.#.#...#...#.#.#.#...#.......#...#.#.#.#...#...#.....N.#
###.#.#######.###.#X#######.#.###.###.###.###.#########R###.#.#.###.#.#.#.#######
#.K.#.....#...#...#.....#...#.#.....#...#.....#.......#.#.#...#...#.#.#.#...#...#
#.#.#####.#.###.#######.#.###.#####.#.#.#.#####.#####.#.#.#.#####.#.#.#.#####.#.#
#.#.#.U.#.#.#...#...#...#...#...#...#.#.#.#...#.#...#...#.#.....#.#...#.......#.#
#.#.###.#.#.#.#####.#.#.###.###.#.#####.#.#.#.#.###.#####.#####.#####.#####.###.#
#.#.#...#...#.....#.#.#...#.#.#.#.....#.#.#.#.#.Y.#.....#.....#.....#.#...#...#.#
#.#.#.#.#########.#.#.#####.#.#.#####.#.#.###.###.###.#.###.#.#####.###.#.#####.#
#.#...#.#.........#.#.........#.#...#...#.#...#...#...#.#...#.#...#...#.#.......#
#.#######.#########.###########.###.###.#.#.###.###.###.#.###.###.###.#.#######.#
#.....#...#.#...........#.......#.....#.#...#...#.#...#...#.........#.#.#...#...#
#.###.#.###.#.#########.#.#######.#####.#####.###.#.#.###############.#.#.#.#.###
#.#.#.#...#.....#.......#.#.............#.....#.....#.....#.....#...#.#...#.#...#
#.#.#.###.#####.#.#######.#.#####.#####.#.#####.#####.###.#.###.#.#.#.#.###.#####
#.#.#...#.O...#.#.#.......#.#...#.#...#.#...#...#...#...#...#...#.#...#...#.....#
#.#.#.#######.###.#.#####.###.#.#.#.#.#.#.#.#####.#.###.#####.###.#######.#####.#
#.#.#.......#.....#.....#t#...#.#.#.#.#.#.#.#.....#.#.......#.....#.....#.#.....#
#.#.#####.#######.#####.###.###.###.#.#.###.#.#####.###########.###.###.###.###.#
#.......#.........#...#...#.#.#.....#.#.#...#.....#.#.....#...#.....#...#...#.#.#
#######.###########.#####.#.#.#######.#.#.#####.###.#.###.#.###.#####.###.###.#.#
#.......#.......#...#...#.#...#...#...#.#.#.....#...#.#.#.#...#.#...#.....#.#...#
#.#####.#.#######.###.#.#.###.#.###.#####.#.#####.###.#.#.###.###.#.#.#####.#.###
#.#...#...#...#...#...#.#.#...#...#.....#...#...#.......#...#...#.#.#.#...#...#.#
#.#.#.#####.#.#.###.###.#.#.#####.#####.#P###.#.#######.###.###.#.#.###.#.###.#.#
#.#.#.......#...#...#.....#.#.....#...#.#.#i..#...#...#.#.....#...#.#...#...#...#
###.###############.#######.#.#.#.###.#.#.#####.###.#.###.#########.#.#####.###.#
#...#.............#...#...#.#.#.#.#...#.#.....#.#...#.....#.......#.#...#...#.#.#
#.###.#######.###.#.#.#.#.#.###.#.#.#.#.#####.#.#.#.#######.#####.#.###.###.#.#.#
#.#.........#.#...#.#...#.......#...#.#.#.....#.#.#.#...#...#...#.#...#...#.#.#.#
#.###########.#.###.###############.###.#.#####.#.###.#.#.###.###.###.###.#.#.#Z#
#...#.........#.#.#.#.#.......#.....#...#.#.....#.#...#...#...#.....#.....#.#...#
###.#.#########.#.#.#.#.#####.#.#####.#.#.###.###.#.#########.#.###.#######.#.###
#.#...#.....#...#.#...#.#...#.#...#...#.#.#...#...#.#.......#.#...#.#.......#.#.#
#.#####.#.###.###.###.#.#.#.#.#####.###.#.#.###.#.#.###.###.#.###.#.#.#######.#.#
#.....#.#...#.#.......#...#.#.#...#.#...#.#.#...#.#.....#...#...#.#.#.#.....#..x#
#.#####.###.#.#############.#.#.#.#.#.###.#.#.###########.###.#.#.###.#.#.#####.#
#.........#.................#...#...#.......#.................#.#.....#.#.......#
#######################################.@.#######################################
#.......#.................#...............#.....#...........#.........#...#.....#
#.#####.#.#########.#####.#.###########.#.#.###.#.#.#######.#.#.#######.#.###.#.#
#...#.#.#.#...#...#.....#.#...#...#.....#.#...#...#.....#...#.#...#.....#.#...#.#
###.#.#.###.#.#.#.#####.#.#####.#.#.###.#.###.#########.#####.###.#.#####.#V#####
#...#.#...#.#.#.#.....#.#.#.....#.#.#...#...#.#.....#.#.....#...#...#...#.#.....#
#.###.###.#.#.#.#####.#.#.#.#####.#.#.###.###.#.#.#.#.#####.###.#######.#.#####.#
#...#...#.#.#.#.....#...#.#.#.....#.#...#.#...#.#.#.W.#...#...#.........#.....#.#
#.#.###.#G#.#.#####.#####.#.#.#####.#####.#.#####.###.###.###.#####.#########.#.#
#.#.#...#...#.#.....#...#...#.#.........#...#...#...#.......#.....#.#.....#...#.#
###.#.#######.#.#######.#####.#.#######.#.###.#.###.#######.#.#####.#.###.#.###.#
#...#.#.....#...#...........#.#.....#...#p....#...#.....#...#......r#.#.....#...#
#.###.#.#.#######.###.#.#####.#.#####.#.#########.#.###.#E###########.#######.#.#
#.#.....#.#.........#.#.#...#.#.#.....#.#...#...#.#.#...#...#.S.....#...#.....#.#
#.#######.#.#########.#.#.#.#.#.#.#######.###.#.#.#.#.#####.###.#######.#.###.###
#.L.....#.#z....#.....#.#.#.#.#.#...#...#.#...#...#.#.#.........#.......#.#.#...#
#.#####.#.#####.#.#####.#.#.#.#####.#.#.#.#.#########.#.#########.#######.#.###.#
#.#...#.#...#...#.....#.#.#...#.....#.#.#.#.......#...#.#...#.....#.#..o#.#.#...#
#.#.###.###.#.#######.###.#####.#####.#.#.#######.#.###.#.#.#.#####.#.#.#.#.#.###
#.#.#...#...#.......#...#.#.#...I.....#.#...#...#.#...#...#b#.#.......#.#...#...#
#.#.#.###.#####.#######.#.#.#.#########.#.#.###.#.###.#######.#.#######.###.###.#
#.#.#.#.#.......#.....#.#.#......y..#.#.#.#.....#...#...#...#.#..l#..g#.#.....#.#
#.#.#.#.#.#######H#####.#.###.#####.#.#.#.###.#####.#.#.#.#.#####.#.#.#.#.#####.#
#...#.#.#...#...#.#..h#.#...#.#...#...#.#.#...#.....#.#.#.#.....#.#.#.#.#.#.#...#
#.###.#.###.#.#.#.#.#.#.###.###.#.#####.#.#####.#######.#.###.#.#.#.#.#.#.#.#.#.#
#.#...#.......#.#...#.#.....#...#...#...#...#...#.....#.#...#.#.#.#.#...#...#.#.#
#.#.###########.#####D#####.#.#####.#.#.#.#.#.###.###.#.###.#.#.#.#.#######.#.#.#
#.#.#.....#.......#.#.....#...#.....#.#.#.#.#.#...#...#.....#.#.#.#...#.....#.#.#
#M#.#.###.#######.#.#####.#####.#####.#####.#.#.###.###.#####.###.###.#.#####.#.#
#.#.....#.#.....#.......#...#.#.#.......#...#...#...#...#...#.......#...#...#.#.#
#.#######.#.###.#.#########.#A#.###.###.#.#######.#######.#.#.###########.#.#.#.#
#.#w....#.#...#.#.#....d....#.#...#...#.#.......#...#...#.#.#..m#.....#...#...#.#
#.#.###.#.###.#.###.#########.###.#####.#.###.#####.#.#.#.#.###.#.###.#.#######.#
#k#...#.#u#...#...B.#.....#.....#.....#.#...#.....#...#.#.#...#.#.#.#...#..n#...#
#.###.#.#.#.#########.###.#.#.#.#####J#.###.###.#.#####.#.###.###.#.#######.#.###
#.#...#...#...#...#...#.#...#.#.....#.#.#...#.#.#.....#.#...#...#.#.........#.#.#
###.#########.#.###F###.#####.#######.#.#.###.#.#####T#.###.###.#.#.#.#####.#.#.#
#...#.......#s#...#.........#...#...#...#.#...#.....#.#...#...#.#q#.#.#.....#...#
#.###.#####.#.#.#.#########.###.#.#.###.#.#.#.#####.#####.###.#.#.#.#.#########C#
#..e......#...#.#.............#...#.....#...#.....#...........#...#.#...........#
#################################################################################
map