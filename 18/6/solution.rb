
require 'set'

Point = Struct.new(:x, :y)

class Point
  def self.of(line)
    Point[*line.split(", ").map(&:to_i)]
  end

  def -(other)
    Point.new(x - other.x, y - other.y)
  end

  def distance(other)
    (self - other).size
  end

  def size
    x.abs + y.abs
  end

  def further_horizontal?(other)
    pt = self - other
    pt.x.abs > pt.y.abs
  end

  def further_vertical?(other)
    pt = self - other
    pt.y.abs > pt.x.abs
  end

  def neighbors
    (x-1).upto(x+1).flat_map { |x|
      (y-1).upto(y+1).map { |y|
        Point.new(x, y)
      }.filter{|pt| pt != self}
    }
  end
end

class ChronalCoordinates
  attr_reader :points
  def initialize(points)
    @points = points
  end

  def self.of(text)
    new(
      text.split("\n")
        .map(&Point.method(:of))
        .to_set
    )
  end

  def largest_finite
    on_board.group_by{|pt| closest(pt)}
      .filter{|pt, _pts| !pt.nil?}
      .filter{|pt, _pts| finite?(pt)}
      .map{|_pt, cluster| cluster.size}.max
  end

  def finite?(point)
    !infinite?(point)
  end

  def infinite?(point)
    above(point).all?{|pt| pt.further_horizontal?(point)} ||
     below(point).all?{|pt| pt.further_horizontal?(point)} ||
     left(point).all?{|pt| pt.further_vertical?(point)} ||
     right(point).all?{|pt| pt.further_vertical?(point)}
  end

  def above(point)
    @points.filter{|pt| pt.y < point.y}
  end

  def below(point)
    @points.filter{|pt| pt.y > point.y}
  end

  def left(point)
    @points.filter{|pt| pt.x < point.x}
  end

  def right(point)
    @points.filter{|pt| pt.x > point.x}
  end

  def closest(point)
    cl = closest_group(point)
    cl.first if cl.size == 1
  end

  def closest_group(point)
    closest_neighbors = @points.group_by{|pt| pt.distance(point)}
      .min_by{|dist, _pts| dist}
      .last
  end

  def on_board
    xmin, xmax = @points.map(&:x).minmax
    ymin, ymax = @points.map(&:y).minmax

    xmin.upto(xmax).flat_map { |x|
      ymin.upto(ymax).map { |y|
        Point[x,y]
      }
    }
  end
end

@example = <<-points
1, 1
1, 6
8, 3
3, 4
5, 5
8, 9
points

@input = <<-points
242, 112
292, 356
66, 265
73, 357
357, 67
44, 303
262, 72
220, 349
331, 301
338, 348
189, 287
285, 288
324, 143
169, 282
114, 166
111, 150
251, 107
176, 196
254, 287
146, 177
149, 213
342, 275
158, 279
327, 325
201, 70
145, 344
227, 345
168, 261
108, 236
306, 222
174, 289
67, 317
316, 302
248, 194
67, 162
232, 357
300, 193
229, 125
326, 234
252, 343
51, 263
348, 234
136, 337
146, 82
334, 62
255, 152
326, 272
114, 168
292, 311
202, 62
points