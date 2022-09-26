
class Moon
  attr_accessor :x, :y, :z, :vx, :vy, :vz
  def initialize(x, y, z)
    self.x, self.y, self.z = [x,y,z]
    self.vx, self.vy, self.vz = [0,0,0]
  end

  def apply_gravity(moons)
    self.vx = vx + moons.map { |other| sign(other.x - self.x) }.sum
    self.vy = vy + moons.map { |other| sign(other.y - self.y) }.sum
    self.vz = vz + moons.map { |other| sign(other.z - self.z) }.sum
  end

  def apply_velocity
    self.x += vx
    self.y += vy
    self.z += vz
  end

  def total_energy
    kinetic_energy * potential_energy
  end

  def potential_energy
    [x, y, z].map(&:abs).sum
  end

  def kinetic_energy
    [vx, vy, vz].map(&:abs).sum
  end

  def show
    puts "pos=<x=#{x.to_s.rjust(4)}, y=#{y.to_s.rjust(4)} z=#{z.to_s.rjust(4)}> " \
      "vel=<x=#{vx.to_s.rjust(4)}, y=#{vy.to_s.rjust(4)} z=#{vz.to_s.rjust(4)}> "
  end

  def position_hash(axis)
    case axis
    when :x
      [x, vx].hash
    when :y
      [y, vy].hash
    when :z
      [z, vz].hash
    end
  end

  private

  def sign(diff)
    if diff == 0
      0
    elsif diff > 0
      +1
    else
      -1
    end
  end
end

class Simulation
  attr_accessor :moons

  MOON_PATTERN = /<x=(\S+), y=(\S+), z=(\S+)>/

  def initialize(moons)
    @moons = moons
  end

  def update
    @moons.each { |m|
      m.apply_gravity(@moons - [self])
    }

    @moons.each(&:apply_velocity)
  end

  def after(n = 1000)
    n.times { update }
    total_energy
  end

  def total_energy
    @moons.map(&:total_energy).sum
  end

  def first_repeated
    lcm(first_repeated_axes)
  end

  def lcm(numbers)
    @numbers = numbers
    all_prime_factors.map { |pf| [pf, [0,1,2].map { |f| factors[f][pf] || 0 }.max] }
      .map { |pf, count| pf ** count }
      .reduce(&:*)
  end

  def all_prime_factors
    factors.flat_map(&:keys).uniq
  end

  def factors
    @factors ||= @numbers.map { |n| prime_factors(n) }
      .map { |factors| factors.group_by(&:itself).transform_values(&:count) }
  end

  def prime_factors(n)
    2.upto(Math.sqrt(n).floor) { |i|
      return [i, *prime_factors(n / i)] if n % i == 0
    }

    [n]
  end

  def first_repeated_axes
    [:x, :y, :z]
      .map { |axis| dup.first_repeated_on(axis) }
  end

  def dup
    Simulation.new(@moons.dup)
  end

  def first_repeated_on(axis)
    mh = moons_hash(axis)
    update ; @i = 1
    loop {
      return @i if moons_hash(axis) == mh
      # puts @i if @i % 10_000 == 0
      update ; @i += 1
    }
  end

  def moons_hash(axis)
    @moons.map { |m| m.position_hash(axis) }.hash
  end

  class << self
    def parse(text)
      new(
        text.lines.map { |line|
          x, y, z = line.match(MOON_PATTERN)
            .captures
            .map(&:to_i)
          Moon.new(x, y, z)
        }
      )
    end
  end
end

def test_update
  sim = Simulation.parse(@example1)

  11.times { |i|
    puts "After #{i} updates"
    sim.moons.each(&:show)
    puts

    sim.update
  }
end

def test
  raise 'example 1' unless Simulation.parse(@example1).after(10) == 179
  raise 'example 2' unless Simulation.parse(@example2).after(100) == 1940
end

def solve
  [
    Simulation.parse(@input).after(1000),
    Simulation.parse(@input).first_repeated,
  ]
end

@input = <<-moons.strip
<x=12, y=0, z=-15>
<x=-8, y=-5, z=-10>
<x=7, y=-17, z=1>
<x=2, y=-11, z=-6>
moons

@example1 = <<-moons.strip
<x=-1, y=0, z=2>
<x=2, y=-10, z=-7>
<x=4, y=-8, z=8>
<x=3, y=5, z=-1>
moons

@example2 = <<-moons.strip
<x=-8, y=-10, z=0>
<x=5, y=5, z=10>
<x=2, y=-7, z=3>
<x=9, y=-8, z=-3>
moons