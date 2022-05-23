
require 'debug'
require 'pry'
require 'set'

PuzzleInput = Struct.new(:text)
class PuzzleInput
  def route_distances
    routes.map do |route|
      dist = 0
      for idx in 1...route.length
        dist += distances[route[idx - 1]][route[idx]]
      end
      dist
    end
  end

  def distances
    @distances ||= compute_distances
  end

  def cities
    edges.map do |edge|
      edge.source
    end.to_a
       .to_set
  end

  def edges
    @edges ||= text.lines.map(&:strip).flat_map do |line|
      nodes, distance = line.split(' = ').map(&:strip)
      source, dest = nodes.split(' to ').map(&:strip)
      distance = distance.to_i
      [Edge.new(source, dest, distance), Edge.new(dest, source, distance)]
    end
  end

  def routes
    subroutes cities
  end

  private
    def subroutes remaining_visits
      if remaining_visits.size == 1
        return [remaining_visits.to_a]
      end

      remaining_visits.flat_map do |city|
        subroutes(remaining_visits - [city]).map do |path|
          debugger if Set === path
          [city] + path
        end
      end
    end

    def compute_distances
      distances = {}

      edges.each do |edge|
        distances[edge.source] ||= {}
        distances[edge.source][edge.dest] = edge.distance
      end

      distances
    end
end

Edge = Struct.new(:source, :dest, :distance)

City = Struct.new(:name, :departures)

# @input = %Q(London to Dublin = 464
# London to Belfast = 518
# Dublin to Belfast = 141)

@input = %Q(Tristram to AlphaCentauri = 34
  Tristram to Snowdin = 100
  Tristram to Tambi = 63
  Tristram to Faerun = 108
  Tristram to Norrath = 111
  Tristram to Straylight = 89
  Tristram to Arbre = 132
  AlphaCentauri to Snowdin = 4
  AlphaCentauri to Tambi = 79
  AlphaCentauri to Faerun = 44
  AlphaCentauri to Norrath = 147
  AlphaCentauri to Straylight = 133
  AlphaCentauri to Arbre = 74
  Snowdin to Tambi = 105
  Snowdin to Faerun = 95
  Snowdin to Norrath = 48
  Snowdin to Straylight = 88
  Snowdin to Arbre = 7
  Tambi to Faerun = 68
  Tambi to Norrath = 134
  Tambi to Straylight = 107
  Tambi to Arbre = 40
  Faerun to Norrath = 11
  Faerun to Straylight = 66
  Faerun to Arbre = 144
  Norrath to Straylight = 115
  Norrath to Arbre = 135
  Straylight to Arbre = 127)
