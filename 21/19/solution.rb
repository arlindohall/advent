$debug = true

def solve(input = nil) =
  Probe
    .new(input || read_input)
    .then { |pb| [pb.unique_beacons.count, pb.dist_between_scanners] }

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

  def dist_between_scanners
    [
      scanner_map
        .values
        .flatten
        .combination(2)
        .map { |s1, s2| s1.dist(s2) }
        .max,
      scanner_map.values.flatten.map(&:offset).map { |o| o.map(&:abs).sum }.max
    ].max
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
      # .each { |c| c.plopp(show_header: false) }
      # rescue StandardError
      # Notice that this fails because the alignment failed, it looks like
      # offset but might be orientation
      #   binding.pry
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
      @offset = offset || [0, 0, 0]
    end

    def dist(other)
      offset.zip(other.offset).map { |a, b| (a - b).abs }.sum
    end

    def overlap?(other, at_least = 12)
      overlapping_beacons(other)
        .count
        .tap do |result|
          puts "-- Scanner #{self.id} overlaps by n=#{result} with scanner #{other.id}"
        end
        .then { |result| result >= at_least }
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
      project_scanner(o)
    end

    def project_scanner(basis)
      self.class.new(id, project(basis))
    end

    def project(basis)
      beacons.map do |beacon|
        Beacon.new(
          basis.matrix_multiply(beacon.coordinates.to_vector).flatten,
          id
        )
      end
    end

    def offset_to(other)
      o = offsets(other).only!
      puts "Scanner #{id} offset by #{o} to #{other.id}"
      self.class.new(id, beacons.map { |beacon| beacon + o }, o)
    end

    # Offset you can change self by to get other's position
    # self + offset = other
    def offsets(other)
      # first_shared_beacon(other).then { |mine, theirs| theirs - mine }
      overlapping_beacons(other).map { |mine, theirs| theirs - mine }.uniq
    end

    def fp_vector(fingerprint)
      fingerprinted_beacons[fingerprint].then { |p1, p2| p1 - p2 }
    end

    # TODO: is there a way to check orientations for all beacons
    # at the same time and pick the one that's the closest
    # Matrix that you can multiply self by to get other
    # orientation * self = other's orientation
    def orientation(other)
      # fp = overlapping_fingerprints(other).first
      # my_edge = fp_vector(fp)
      # their_edge = other.fp_vector(fp)

      # rotation_for(my_edge, their_edge)
      # TODO: it seems like the most common should work but it doesn't
      # overlapping_fingerprints(other)
      #   .map { |fp| [fp_vector(fp), other.fp_vector(fp)] }
      #   .map { |my_edge, their_edge| rotation_for(my_edge, their_edge) }
      #   .compact
      #   .count_values
      #   .max_by { |v, count| count }
      #   .first

      ROTATIONS
        .filter { |r| fp_overlap_rotates(other, r) }
        .find { |r| project_scanner(r).offsets(other).count == 1 } ||
        # Shouldn't need the second one but I can't be fucked, it's quicker and works so whatever
        ROTATIONS.find { |r| project_scanner(r).offsets(other).count == 1 }
      # rescue StandardError => e
      #   binding.pry
    end

    def fp_overlap_rotates(other, rotation)
      fp = overlapping_fingerprints(other).first
      my_edge = fp_vector(fp)
      their_edge = other.fp_vector(fp)
      rotation.matrix_multiply(my_edge.to_vector) == their_edge.to_vector
    end

    # def rotation_for(my_edge, their_edge)
    #   ROTATIONS
    #     .filter do |rotation|
    #       rotation.matrix_multiply(my_edge.to_vector) == their_edge.to_vector
    #     end
    #     .only!
    #   # Will error when two columns same, e.g. [1, 1, 2], [1, -1, 2]
    #   # rescue StandardError
    #   #   # binding.pry
    #   #   nil
    # end

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
