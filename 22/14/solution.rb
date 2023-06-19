$_debug = false

def solve =
  SandPit.parse(read_input).then { |it| [it.fill, it.fill_with_floor] }

class SandPit
  shape :barriers, :sand

  def fill
    @sand = Set.new
    fill_from(500, 0, floor: false)

    sand.size
  end

  def fill_with_floor
    @sand = Set.new
    fill_from(500, 0, floor: true)

    sand.size
  end

  def fill_from(x, y, floor:)
    return 0 if occluded?(x, y, floor:)
    return -1 if y > max_y + 5

    below = fill_from(x, y + 1, floor:)
    return below if below < 0

    left = fill_from(x - 1, y + 1, floor:)
    return left if left < 0

    right = fill_from(x + 1, y + 1, floor:)
    return right if right < 0

    sand << [x, y]

    below + left + right + 1
  ensure
    _debug(x:, y:, below:, left:, right:, floor:)
  end

  def occluded?(x, y, floor:)
    return true if floor && y > max_y + 1
    barriers.include?([x, y]) || sand&.include?([x, y])
  end

  memoize def max_y
    barriers.map(&:second).max
  end

  def show!
    blocks = barriers + sand.to_a
    xn, xx = blocks.map(&:first).minmax
    yn, yx = blocks.map(&:second).minmax

    (yn..yx).each do |y|
      (xn..xx).each do |x|
        print(
          if barriers.include?([x, y])
            "#"
          elsif sand&.include?([x, y])
            "o"
          else
            "."
          end
        )
      end
      puts
    end
  end

  class << self
    def parse(text)
      new(
        barriers:
          text
            .split("\n")
            .flat_map do |shape|
              shape.split(" -> ").then { |corners| points_for(corners) }
            end
            .to_set
      )
    end

    def points_for(corners)
      corners = corners.map { |it| it.split(",") }.sub_map(&:to_i)
      points = []
      start = corners.first

      corners
        .drop(1)
        .each do |finish|
          points += line_from(start, finish)

          _debug(points:, start:, finish:, line: line_from(start, finish))
          start = finish
        end

      points
    end

    def line_from(start, finish)
      sx, sy = start
      fx, fy = finish

      sx.to(fx).flat_map { |x| sy.to(fy).map { |y| [x, y] } }
    end
  end
end
