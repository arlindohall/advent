def solve(input = read_input) =
  Galaxies
    .new(input)
    .then do |g|
      [g.post_expansion_distance_sum, g.million_expansion_distance_sum]
    end

class Galaxies
  def initialize(text)
    @text = text
  end

  def post_expansion_distance_sum
    # _debug("expanded", expansion_distances)
    expansion_distances.sum
  end

  def million_expansion_distance_sum
    million_expansion_distances.sum
  end

  def expansion_distances
    galaxy_pairs.map { |g1, g2| expanded_distance(g1, g2) }
  end

  def million_expansion_distances
    galaxy_pairs.map { |g1, g2| million_expanded_distance(g1, g2) }
  end

  def galaxy_pairs
    galaxies.combination(2)
  end

  memoize def galaxies
    id = 0
    @text
      .split("\n")
      .each_with_index
      .flat_map do |line, y|
        line.chars.each_with_index.map do |ch, x|
          id += 1 if ch == "#"
          Galaxy.new(x:, y:, id:) if ch == "#"
        end
      end
      .compact
  end

  def expanded_distance(g1, g2)
    # _debug("expanding", g1, g2, ExpandedDistance.new(gaps, g1, g2).compute)
    ExpandedDistance.new(gaps, g1, g2).compute
  end

  def million_expanded_distance(g1, g2)
    ExpandedDistance.new(gaps, g1, g2, MillionSpaceExpansion).compute
  end

  memoize def gaps
    [all_x_values - galaxy_x_values, all_y_values - galaxy_y_values]
  end

  def all_x_values
    0.upto(galaxies.map(&:x).max).to_a
  end

  def all_y_values
    0.upto(galaxies.map(&:y).max).to_a
  end

  def galaxy_x_values
    galaxies.map(&:x).uniq
  end

  def galaxy_y_values
    galaxies.map(&:y).uniq
  end
end

class Galaxy
  shape :x, :y, :id
end

class ExpandedDistance
  def initialize(
    gaps,
    galaxy,
    other_galaxy,
    expansion_factor = SingleSpaceExpansion
  )
    @gaps = gaps
    @galaxy = galaxy
    @other_galaxy = other_galaxy
    @expansion_factor = expansion_factor
  end

  def compute
    gx1, gy1 = @galaxy.x, @galaxy.y
    gx2, gy2 = @other_galaxy.x, @other_galaxy.y

    [gx1 - gx2, gy1 - gy2, expansion_factor].map(&:abs).sum
  end

  def expansion_factor
    @expansion_factor.new(@gaps, @galaxy, @other_galaxy).compute
  end
end

class SingleSpaceExpansion
  def initialize(gaps, galaxy, other_galaxy)
    @gaps = gaps
    @galaxy = galaxy
    @other_galaxy = other_galaxy
  end

  def compute
    x_expansion_factor + y_expansion_factor
  end

  def x_expansion_factor
    @gaps.first.count { |gap| @galaxy.x.to(@other_galaxy.x).include?(gap) }
  end

  def y_expansion_factor
    @gaps.second.count { |gap| @galaxy.y.to(@other_galaxy.y).include?(gap) }
  end
end

class MillionSpaceExpansion
  def initialize(gaps, galaxy, other_galaxy)
    @gaps = gaps
    @galaxy = galaxy
    @other_galaxy = other_galaxy
  end

  def compute
    x_expansion_factor + y_expansion_factor
  end

  def x_expansion_factor
    @gaps.first.count { |gap| @galaxy.x.to(@other_galaxy.x).include?(gap) } *
      almost_one_million
  end

  def y_expansion_factor
    @gaps.second.count { |gap| @galaxy.y.to(@other_galaxy.y).include?(gap) } *
      almost_one_million
  end

  def almost_one_million
    # 100 - 1 # for example
    1_000_000 - 1
  end
end
