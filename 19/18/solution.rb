$_debug = false

STARTING_POINTS = %w[@ $ % &]

class Tunnels
  attr_reader :steps, :location

  def initialize(graph, location, steps = 0)
    @graph = graph
    @location = location
    @steps = steps
  end

  def dup
    Tunnels.new(@graph, @location, @steps)
  end

  # I feel really stupid but I can't figure out what the right answer was
  # so I literally just copied https://todd.ginsberg.com/post/advent-of-code/2019/day18/
  # so I can move on to the next part and maybe idk comeback to this later todo
  def find_all_keys
    minimum_steps(Set[@location], Set.new, {})
  end

  # I tried running with truffleruby in hopes that it would speed up, but with
  # MRuby, I got ~300s and with TR I got something like ~450s
  #
  # I really just have no idea what's going on with this solution.
  def find_all_keys_four_searchers
    minimum_steps(STARTING_POINTS.dup.to_set, Set.new, {})
  end

  def minimum_steps(starting_points, keys, distances)
    @search_count ||= 0
    @search_count += 1
    if @search_count % 10_000 == 0
      puts "Looking for minimum steps from points=#{starting_points}, " \
             "keys=#{keys.size}, " \
             "distances=#{distances.size}"
    end

    state = [starting_points, keys]

    return distances[state] if distances[state]

    distances[state] = find_reachable_points(starting_points, keys)
      .map do |key, distance, source|
        distance +
          minimum_steps(
            (starting_points - Set[source]) + Set[key],
            keys + Set[key],
            distances
          )
      end
      .min || 0
  end

  def find_reachable_points(starting_points, keys)
    if $_debug
      puts "-Looking for reachable points from points=#{starting_points}, " \
             "keys=#{keys}"
    end

    starting_points.flat_map do |point|
      find_reachable_keys(point, keys).map do |key, distance|
        [key, distance, point]
      end
    end
  end

  def find_reachable_keys(point, keys)
    if $_debug
      puts "--Looking for reachable keys from point=#{point}, " \
             "keys=#{keys}"
    end

    search_queue = [point]
    distances = { point => 0 }
    until search_queue.empty?
      name = search_queue.shift
      @graph
        .neighbors(name)
        .each do |neighbor, distance|
          puts "---Checking if we can reach #{neighbor} from #{name}" if $_debug
          unless distances[name]
            raise "Trying to visit #{neighbor} without first visiting #{name}"
          end
          next unless can_visit?(neighbor, keys)
          next if distances[neighbor]
          distances[neighbor] = distances[name] + distance
          search_queue << neighbor
        end
    end

    puts "--Found distances=#{distances}" if $_debug
    distances
      .filter { |name, _| key?(name) }
      .reject { |name, _| name == point }
      .reject { |name, _| keys.include?(name) }
      .map { |name, distance| [name, distance] }
  end

  def can_visit?(name, keys)
    return true unless door?(name)

    keys.include?(name.downcase)
  end

  def key?(name)
    name =~ /[a-z]/
  end

  def door?(name)
    name =~ /[A-Z]/
  end

  class << self
    def parse(text)
      graphify(*map_properties(text))
    end

    def map_properties(text)
      [
        text
          .split("\n")
          .each_with_index
          .flat_map do |line, y|
            line.split("").each_with_index.map { |ch, x| [[x, y], ch] }
          end
          .to_h,
        text.split("\n").first.size,
        text.split("\n").size
      ]
    end

    def graphify(map, x, y)
      new(graph_from(map, x, y), "@")
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
    print point unless @nodes[point]
    @nodes[point].neighbors
  end

  Node = Struct.new(:name, :location, :neighbors)

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
      nodes.keys.each do |name|
        nodes[name].neighbors = dup.fill_neighbors(name)
      end
      Graph.new(nodes)
    end

    def nodes
      @nodes ||=
        @map.each_with_object({}) do |(location, ch), nodes|
          raise "Duplicate node #{ch} at #{location}" if nodes[ch]
          nodes[ch] = Node.new(ch, location) if ch =~ /[A-Za-z@$%&]/
        end
    end

    def node(name)
      nodes[name]
    end

    def fill_neighbors(key)
      unless node(key)
        raise "Unknown key #{key} value=#{node(key)} map=#{@map[node(key).location]}"
      end
      initialize_search(key)
      # puts "Searching for #{@starting_point.name}"

      until @search_queue.empty?
        update_search_queue
        @distance += 1
      end

      # p @found_neighbors.map(&:first).uniq
      # p @found_neighbors.map(&:first)

      unless @found_neighbors.map(&:first).uniq.size == @found_neighbors.size
        raise "Expected unique paths to neighbors"
      end
      @found_neighbors
    end

    def initialize_search(key)
      @found_neighbors = []
      @starting_point = node(key)
      @distance = 1
      @search_queue = neighbors(@starting_point.location)
      @map[@starting_point.location] = "#"
    end

    def update_search_queue
      _debug

      @search_queue =
        @search_queue
          .map { |location| visit(location) }
          .compact
          .flat_map { |location| neighbors(location) }
    end

    def visit(location)
      return if @map[location] == "#"
      @map[location] = "." if entrance?(location)

      if @map[location] =~ /[A-Za-z]/
        @found_neighbors << [@map[location], @distance]
        return
      end

      unless @map[location] == "."
        raise "Expected path but found #{@map[location]}(#{location})"
      end
      location
    ensure
      @map[location] = "#"
    end

    def entrance?(location)
      STARTING_POINTS.include?(@map[location])
    end

    def neighbors(location)
      x, y = location
      [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]].filter do |loc|
        @map[loc] && @map[loc] != "#"
      end
    end

    def _debug
      return unless $_debug
      print "\033[H"
      0.upto(@y) do |y|
        0.upto(@x) { |x| print @map[[x, y]] || " " }
        puts
      end
      puts @search_queue.size
    end
  end
end

def test
  [
    @example1,
    8,
    @example2,
    86,
    @example3,
    132,
    @example4,
    136,
    @example5,
    81
  ].each_slice(2) do |input, expected|
    actual = Tunnels.parse(input).find_all_keys
    raise "Expected #{expected} got #{actual}" unless actual == expected
  end

  [@example6, 8, @example7, 24, @example8, 32, @example9, 72].each_slice(
    2
  ) do |input, expected|
    actual = Tunnels.parse(input).find_all_keys_four_searchers
    raise "Expected #{expected} got #{actual}" unless actual == expected
  end

  :success
end

def solve
  [
    Tunnels.parse(@input).find_all_keys,
    Tunnels.parse(@input2).find_all_keys_four_searchers
  ]
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

@example6 = <<-map.strip
#######
#a.#Cd#
##@#$##
#######
##%#&##
#cB#Ab#
#######
map

@example7 = <<-map.strip
###############
#d.ABC.#.....a#
######@#$######
###############
######%#&######
#b.....#.....c#
###############
map

@example8 = <<-map.strip
#############
#DcBa.#.GhKl#
#.###@#$#I###
#e#d#####j#k#
###C#%#&###J#
#fEbA.#.FgHi#
#############
map

@example9 = <<-map.strip
#############
#g#f.D#..h#l#
#F###e#E###.#
#dCba@\#$BcIJ#
#############
#nK.L%#&G...#
#M###N#H###.#
#o#m..#i#jk.#
#############
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

@input2 = <<-map.strip
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
#.........#.................#...#...#..@#&..#.................#.#.....#.#.......#
#################################################################################
#.......#.................#............$#%#.....#...........#.........#...#.....#
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
