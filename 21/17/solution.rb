def solve =
  [
    Projectile.parse(read_input).max_height,
    Projectile.parse(read_input).all_initial_velocities.count
  ]

class Projectile
  attr_reader :x_min, :x_max, :y_min, :y_max
  def initialize(x_min:, x_max:, y_min:, y_max:)
    @x_min = x_min
    @x_max = x_max
    @y_min = y_min
    @y_max = y_max
  end

  # Heights are triangle numbers
  def max_height
    triangle_sum(max_velocity)
  end

  def all_initial_velocities
    all_times
      .flat_map do |time|
        x_times[time].flat_map { |x| y_times[time].map { |y| [x, y] } }
      end
      .uniq
  end

  def all_times
    x_times.keys.to_set & y_times.keys.to_set
  end

  memoize def x_times
    x_times = {}
    0.upto(x_max) do |vx_i|
      x = 0
      vx = vx_i
      max_t.times do |t|
        x += vx
        vx = [vx - 1, 0].max
        x_times[t] ||= []
        x_times[t] << vx_i if x_range.include?(x)
      end
    end

    x_times
  end

  memoize def y_times
    y_times = {}
    (y_min).upto(-y_min) do |vy_i|
      y = 0
      vy = vy_i
      (-2 * y_min + 2).times do |t|
        y += vy
        vy = vy - 1
        y_times[t] ||= []
        y_times[t] << vy_i if y_range.include?(y)
      end
    end

    y_times
  end

  memoize def x_range = (x_min..x_max)
  memoize def y_range = (y_min..y_max)

  def max_t
    y_times.keys.max
  end

  def max_velocity
    y_min.abs - 1
  end

  memoize def triangle_sum(n)
    (n * (n + 1)) / 2
  end

  def self.parse(string)
    xs = string.split(",").first.split("=").second.split("..").map(&:to_i).sort
    ys = string.split(",").second.split("=").second.split("..").map(&:to_i).sort

    new(x_min: xs.first, x_max: xs.last, y_min: ys.first, y_max: ys.last)
  end
end
