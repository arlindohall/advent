$debug = true

class Probe
  attr_reader :text
  def initialize(text)
    @text = text
  end

  def unique_beacons
    all_beacons.map(&:coordinates).uniq
  end

  def all_beacons
    scanners[0].beacons + scanner_map.values.flatten.map(&:beacons).flatten
  end

  memoize def scanners
    text.split("\n\n").map { |block| Scanner.parse(block) }
  end

  memoize def scanner_map
    build_scanner_map(scanners.drop(1), scanners.first, {})
  end

  def build_scanner_map(unmatched, current, map)
    return map if unmatched.empty?

    matched = unmatched.filter { |scanner| current.overlap?(scanner) }
    unmatched.reject! { |scanner| matched.include?(scanner) }

    map[current.id] = matched.map do |scanner|
      scanner.orient_to(current).offset_to(current)
    end

    map[current.id].each do |scanner|
      current
        .overlapping_beacons(scanner)
        .sub_map(&:coordinates)
        .tap { |cds| cds.each { |cd| assert! cd.first == cd.second } }
        .map(&:first)
        .sort
        .each { |c| c.plopp(show_header: false) }
    end

    map[current.id].each do |scanner|
      build_scanner_map(unmatched, scanner, map)
    end

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

    attr_reader :id, :beacons, :offset
    def initialize(id, beacons, offset = nil)
      @id = id
      @beacons = beacons
      @offset = offset
    end

    def overlap?(other, at_least = 12)
      overlapping_beacons(other).count >= at_least
    end

    def overlapping_beacons(other)
      overlapping_fingerprints(other)
        .map { |fp| fingerprinted_beacons[fp] }
        .flatten
        .uniq
        .map { |bc| [bc, matching_beacon(bc, other)] }
    end

    def matching_beacon(beacon, other)
      my_fps = fingerprints_for(beacon).to_set
      other.beacons.max_by do |other_beacon|
        (other.fingerprints_for(other_beacon).to_set & my_fps).count
      end
    end

    def fingerprints_for(beacon)
      fingerprinted_beacons.keys.filter do |fp|
        fingerprinted_beacons[fp].include?(beacon)
      end
    end

    def overlapping_fingerprints(other)
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
      self.class.new(id, beacons.map { |beacon| beacon + o }, o)
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
      overlapping_fingerprints(other).first
    end

    def first_shared_beacon(other)
      beacon =
        fingerprinted_beacons[overlapping_fingerprints(other).first].first
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

    memoize def shared_fingerprints(beacon)
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
