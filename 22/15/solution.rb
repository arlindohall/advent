$_debug = false

class SensorArray
  shape :sensor_map

  def positions_without_beacon(y = 2_000_000)
    no_beacons =
      sensors
        .map { |s| coverage(s, y) }
        .compact
        .sort_by(&:first)
        .reduce([]) do |interval_list, interval|
          combine_and_sort(interval_list, interval)
        end

    _debug(no_beacons:)
    no_beacons.map { |interval| interval.last - interval.first + 1 }.sum -
      beacons_in(no_beacons, y)
  end

  def tuning_frequency(max_y = 4_000_000)
    # show_all_sensors if $_debug

    x, y = single_position_without(max_y)

    4_000_000 * x + y
  end

  # def exhaust(max_y)
  #   0.upto(max_y) do |y|
  #     puts y
  #     0.upto(max_y) do |x|
  #       next if sensors.any? { |s| dist_to([x, y], s) <= dist(s) }
  #       return x, y
  #     end
  #   end
  # end

  def cluster_borders
    biggest_cluster.flatten.map { |i| sensors[i] }.map { |s| borders(s) }
  end

  def borders(sensor)
    dist(sensor)
  end

  def big_from_big_cluster
    biggest_cluster.filter do |i|
      s = sensors[i]
      biggest_cluster
        .map { |i| sensors[i] }
        .filter { |other| dist_to(s, other) < dist(s) }
        .count > 1
    end
  end

  memoize def biggest_cluster
    sensors
      .map do |sensor|
        sensors
          .each_with_index
          .filter do |other, i|
            ds = dist(sensor)
            dt = dist(other)

            ds + dt + 1 >= dist_to(sensor, other)
            # [ds + dt + 1, ds + dt + 2].include? dist_to(sensor, other)
          end
          .map { |_other, i| i }
      end
      .each_with_index
      .max_by { |neighbors, idx| neighbors.size }
      .flatten
      .uniq
  end

  def coverage(sensor, level)
    d = dist(sensor)
    x, y = sensor

    leftover = d - (y - level).abs

    return nil if leftover < 0

    [x - leftover, x + leftover]
  end

  def combine_and_sort(interval_list, interval)
    _debug(interval_list:, interval:)

    return [interval] if interval_list.empty?

    if interval_list.last.last >= interval.first
      interval_list[..-2] +
        [
          [
            interval_list.last.first,
            [interval_list.last.last, interval.last].max
          ]
        ]
    else
      interval_list + [interval]
    end
  end

  def beacons_in(no_beacons, y)
    sensor_map
      .values
      .uniq
      .filter { |beacon| beacon.last == y }
      .filter do |beacon|
        no_beacons.any? { |s, f| (s..f).include?(beacon.first) }
      end
      .count
  end

  memoize def dist(sensor)
    dist_to(sensor, sensor_map[sensor])
  end

  def dist_to(sensor, point)
    xa, ya = sensor
    xb, yb = point

    (xa - xb).abs + (ya - yb).abs
  end

  def sensors
    sensor_map.keys
  end

  def show_corners(x = nil, y = nil, d = nil)
    x, y = sensors[x] if y.nil? || d.nil?
    d = dist([x, y]) if d.nil?

    0.upto(20) do |ya|
      0.upto(20) do |xa|
        if [xa, ya] == [14, 11]
          print("X")
          next
        end
        print ((dist_to([xa, ya], [x, y]) >= d ? "." : "#").darken_squares)
      end
      puts
    end
  end

  def show_all_sensors
    0.upto(20) do |ya|
      0.upto(20) do |xa|
        if [xa, ya] == [14, 11]
          print("X")
          next
        end
        print (
                (
                  if sensors.any? { |s| dist_to([xa, ya], s) <= dist(s) }
                    "#"
                  else
                    "."
                  end
                ).darken_squares
              )
      end
      puts
    end
  end

  def cheat_corners
    sensors
      .each_with_index
      .filter do |s, _i|
        _debug(s:, dist: dist(s), dist_to: dist_to(s, [14, 11]))
        dist_to(s, [14, 11]) == dist(s) + 1
      end
      .map { |s, i| i }
      .each { |s| show_corners(s) }
  end

  class << self
    def parse(text)
      new(
        sensor_map:
          text
            .split("\n")
            .map { |l| l.split(":") }
            .sub_map do |entity|
              [
                entity.match(/x=(-?\d+)/).captures.first.to_i,
                entity.match(/y=(-?\d+)/).captures.first.to_i
              ]
            end
            .to_h
      )
    end
  end
end
