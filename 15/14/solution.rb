
Reindeer = Struct.new(:name, :speed, :travel_time, :rest_time)
Journey = Struct.new(:speed, :travel_time, :rest_time, :time)

class Reindeer
  def travel time
    Journey.new(speed, travel_time, rest_time, time)
  end
end

class Journey
  def distance
    full_paths * speed + partial_paths * speed
  end

  def full_paths
    (time / full_path_time) * travel_time
  end

  def full_path_time
    travel_time + rest_time
  end

  def partial_paths
    last_leg > travel_time ? travel_time : last_leg
  end

  def last_leg
    time % full_path_time
  end
end

# Input = %Q(
#   Dancer can fly 16 km/s for 11 seconds, but then must rest for 162 seconds.
#   Comet can fly 14 km/s for 10 seconds, but then must rest for 127 seconds.
# )

Input = %Q(
  Rudolph can fly 22 km/s for 8 seconds, but then must rest for 165 seconds.
  Cupid can fly 8 km/s for 17 seconds, but then must rest for 114 seconds.
  Prancer can fly 18 km/s for 6 seconds, but then must rest for 103 seconds.
  Donner can fly 25 km/s for 6 seconds, but then must rest for 145 seconds.
  Dasher can fly 11 km/s for 12 seconds, but then must rest for 125 seconds.
  Comet can fly 21 km/s for 6 seconds, but then must rest for 121 seconds.
  Blitzen can fly 18 km/s for 3 seconds, but then must rest for 50 seconds.
  Vixen can fly 20 km/s for 4 seconds, but then must rest for 75 seconds.
  Dancer can fly 7 km/s for 20 seconds, but then must rest for 119 seconds.
)

class Race
  REGEX = /(\w+) can fly (\d+) km\/s for (\d+) seconds, but then must rest for (\d+) seconds./

  def reindeer
    @reindeer ||= Input.strip
      .lines
      .map(&:strip)
      .map do |line|
        name, speed, travel, rest = REGEX.match(line).to_a[1..]
        Reindeer.new(name, speed.to_i, travel.to_i, rest.to_i)
      end
  end

  def reset
    @scores = reindeer.map do |r|
      [r.name, 0]
    end.to_h

    @distances = reindeer.map do |r|
      [r.name, 0]
    end.to_h
  end

  def race t
    reset
    1.upto(t) do |i|
      reindeer.each do |r|
        @distances[r.name] = r.travel(i).distance
      end

      reindeer.each do |r|
        if @distances[r.name] == @distances.values.max
          @scores[r.name] += 1
        end
      end
    end

    [@scores, @distances]
  end
end

# part 1: Race.new.race(N)[1].values.max
# part 2: Race.new.race(N)[0].values.max