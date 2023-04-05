$debug = true

class Probe
  attr_reader :text
  def initialize(text)
    @text = text
  end

  memoize def scanners
    text.split("\n\n").map { |block| Scanner.parse(block) }
  end

  memoize def scanner_map
    build_scanner_map(scanners.drop(1), scanners.first, {}).then do |map|
      translate_values!(map, scanners[0])
    end
  end

  def build_scanner_map(unmatched, current, map)
    return if unmatched.empty?

    matched = unmatched.select { |scanner| current.overlap?(scanner) }
    unmatched.reject! { |scanner| matched.include?(scanner) }

    map[current.id] = matched
    matched.each { |scanner| build_scanner_map(unmatched, scanner, map) }

    map
  end

  # todo: orient to whole scanner
  def translate_values!(map, base)
    return unless map[base.id]

    map[base.id] = map[base.id].map do |scanner|
      scanner.orient_to(base).offset_to(base)
    end

    map[base.id].each { |scanner| translate_values!(map, scanner) }
    map
  end

  class Scanner
    # ROTATIONS = [[1, 0], [0, 1], [-1, 0], [0, -1]].permutation(2).to_a
    ROTATIONS = [
      [1, 0, 0],
      [0, 1, 0],
      [0, 0, 1],
      [-1, 0, 0],
      [0, -1, 0],
      [0, 0, -1]
    ].permutation(3).to_a

    attr_reader :id, :beacons
    def initialize(id, beacons)
      @id = id
      @beacons = beacons
    end

    def overlap?(other, at_least = 12)
      overlap(other).count >= at_least
    end

    def overlap(other)
      fingerprinted_beacons.keys.to_set &
        other.fingerprinted_beacons.keys.to_set
    end

    def orient_to(other)
      o = orientation(other)
      self.class.new(
        id,
        beacons.map do |beacon|
          Beacon.new(
            o.matrix_multiply(beacon.coordinates.to_vector).flatten,
            id
          )
        end
      )
    end

    def offset_to(other)
      o = offset(other)
      puts "Scanner #{id} offset by #{o} to #{other.id}"
      self.class.new(id, beacons.map { |beacon| beacon + o })
    end

    # Offset you can change self by to get other's position
    # self + offset = other
    def offset(other)
      first_shared_beacon(other).then { |mine, theirs| theirs - mine }
    end

    # Matrix that you can multiply self by to get other
    # orientation * self = other's orientation
    def orientation(other)
      my_edge =
        fingerprinted_beacons[first_shared_fingerprint(other)].then do |p1, p2|
          p1 - p2
        end
      their_edge =
        other.fingerprinted_beacons[
          first_shared_fingerprint(other)
        ].then { |p1, p2| p1 - p2 }

      ROTATIONS.find do |rotation|
        rotation.matrix_multiply(my_edge.to_vector) == their_edge.to_vector
      end
    end

    def first_shared_fingerprint(other)
      overlap(other).first
    end

    def first_shared_beacon(other)
      beacon = fingerprinted_beacons[overlap(other).first].first
      fingerprints = shared_fingerprints(beacon)
      other_beacon =
        other
          .fingerprinted_beacons
          .filter { |fb, beacons| fingerprints.include?(fb) }
          .map { |fb, beacons| beacons.to_set }
          .reduce(&:&)
          .only!
      [beacon, other_beacon]
    end

    def any_beacon
      fingerprinted_beacons.values.first.first
    end

    def shared_fingerprints(beacon)
      fingerprinted_beacons
        .filter do |fp, beacons|
          beacons.any? { |bc| bc.coordinates == beacon.coordinates }
        end
        .map { |fp, beacons| fp }
    end

    memoize def fingerprinted_beacons
      beacons
        .combination(2)
        .map do |first, second|
          [first.distance_squared(second), [first, second]]
        end
        .to_h
    end

    def self.parse(block)
      id = block.match(/scanner (\d+)/).captures.first.to_i
      beacons =
        block
          .split("---")
          .last
          .split
          .map { |line| Beacon.new(line.split(",").map(&:to_i), id) }
      new(id, beacons)
    end
  end

  class Beacon
    attr_reader :coordinates, :scanner
    def initialize(coordinates, scanner)
      @coordinates = coordinates
      @scanner = scanner
    end

    def distance_squared(other)
      (self - other).map(&:square).sum
    end

    def -(other)
      coordinates.zip(other.coordinates).map { |a, b| (a - b) }
    end

    def +(other)
      case other
      when Array
        coordinates.zip(other)
      when Beacon
        coordinates.zip(other.coordinates)
      end
        .map { |a, b| (a + b) }
        .then { |coordinates| Beacon.new(coordinates, scanner) }
    end
  end
end
