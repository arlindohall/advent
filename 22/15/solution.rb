$_debug = false

def solve =
  SensorArray
    .then { |it| it.parse(read_input) }
    .then { |it| [it.positions_without_beacon, it.tuning_frequency] }

class SensorArray
  shape :sensor_map

  def positions_without_beacon(y = 2_000_000, include_beacons: false)
    no_beacons =
      sensors
        .map { |s| coverage(s, y) }
        .compact
        .sort_by(&:first)
        .reduce([]) do |interval_list, interval|
          combine_and_sort(interval_list, interval)
        end

    _debug("Found positions without beacons", no_beacons:)
    return no_beacons if include_beacons

    no_beacons.map { |interval| interval.last - interval.first + 1 }.sum -
      beacons_in(no_beacons, y)
  end

  def tuning_frequency(max_y = 4_000_000)
    # show_all_sensors if $_debug

    y, int = single_position_without(max_y)
    _debug(y:, int:)

    x = space_in(int)

    4_000_000 * x + y
  end

  def single_position_without(max_y)
    skip_ahead = max_y > 20 ? 2_900_000 : 0
    (skip_ahead).upto(max_y) do |y|
      # puts y if y % 10_000 == 0
      size, intervals = without_beacon_in(max_y, y)
      _debug("Checking size of leftovers", y:, size:, intervals:)
      return y, intervals if size == 0
    end
    nil
  end

  def without_beacon_in(max_y, y)
    intervals =
      positions_without_beacon(
        y,
        include_beacons: true
      ).map do |xi_start, xi_end|
        xt_start, xt_end =
          [[[xi_start, 0].max, max_y].min, [[xi_end, 0].max, max_y].min]
        _debug("Interval truncated: ", :xt_start, xt_start, :xt_end, xt_end)
        [xt_start, xt_end]
      end

    [
      intervals.map { |xs, xe| xe - xs + 1 }.map { |s| -s }.sum + max_y,
      intervals
    ]
  end

  def space_in(interval)
    interval.flatten.drop(1).each_slice(2) { |a, b| return a + 1 if a + 1 != b }
  end

  def coverage(sensor, level)
    d = dist(sensor)
    x, y = sensor

    leftover = d - (y - level).abs

    return nil if leftover < 0

    [x - leftover, x + leftover]
  end

  def combine_and_sort(interval_list, interval)
    # _debug(interval_list:, interval:)

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
