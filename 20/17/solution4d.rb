#!/usr/bin/env ruby
require 'set'

class Point < Struct.new(:w, :x, :y, :z)
  def neighbors
    3.times.flat_map { |h|
      3.times.flat_map { |i|
        3.times.flat_map { |j|
          3.times.map { |k|
            Point[h+w-1, i+x-1, j+y-1, k+z-1]
          }
        }
      }
    }
  end
end

class Grid
  def initialize(points)
    @space = Set.new(points)
  end

  def count
    @space.count
  end

  def next
    Grid.new(all_neighbors.select { |point|
      if @space.include? point
        (2..3).include? active_neighbors(point)
      else
        active_neighbors(point) == 3
      end
    })
  end

  def neighbors
    Set.new(@space.flat_map{ |point| point.neighbors })
  end

  def active_neighbors(point)
    strict_neighbors = (point.neighbors - [point])
    strict_neighbors.select { |n| @space.include?(n) }.count
  end

  def all_neighbors
    @space.flat_map(&:neighbors)
  end
end




#####################################################
##################### DEBUGGING #####################
#####################################################

class Grid
  def bounds
    [
    @space.map(&:w).min,
    @space.map(&:x).min,
    @space.map(&:y).min,
    @space.map(&:z).min,

    @space.map(&:w).max,
    @space.map(&:x).max,
    @space.map(&:y).max,
    @space.map(&:z).max
    ]
  end

  def to_s
    minw, minx, miny, minz, maxw, maxx, maxy, maxz = bounds

    (minw..maxw).map { |w|
      (minz..maxz).map { |z|
        ["z=#{z} / w=#{w}",
          (miny..maxy).map { |y|
            (minx..maxx).map { |x|
              if @space.include? Point[w, x, y, z]
                '#'
              else
                '.'
              end
            }.join
          }.reverse.join("\n")
        ].join("\n")
      }.join("\n")
    }.join("\n\n")
  end

  def inspect
    self.to_s
  end
end


# @grid = Grid.new([
#   Point[0, 0, 0, 0],
#   Point[0, 1, 0, 0],
#   Point[0, 2, 0, 0],
#   Point[0, 2, 1, 0],
#   Point[0, 1, 2, 0]
# ])

# 6.times do |i|
#   puts "... calculating #{i}th iteration"
#   @grid = @grid.next
# end

# puts @grid
# puts @grid.count

@grid = "###...#.
.##.####
.####.##
###.###.
.##.####
#.##..#.
##.####.
.####.#.".lines
    .map(&:strip)
    .map(&:chars)
    .each_with_index.map { |row, y|
      row.each_with_index.map { |col, x|
        if col == "#"
          Point.new(0, x, y, 0)
        end
      }.filter{ |p| !p.nil? }
    }
    .flat_map{ |x| x }

@grid = Grid.new(@grid)

6.times do |i|
  puts "... calculating #{i}th iteration"
  @grid = @grid.next
end

puts @grid.count
