$_debug = false

def solve(input = nil) =
  Lava
    .parse(input || read_input)
    .then { |it| [it.surfaces, it.exterior_surfaces] }

class Lava
  SIDES =
    Set[[0, 0, 1], [0, 0, -1], [0, 1, 0], [0, -1, 0], [1, 0, 0], [-1, 0, 0]]

  shape :droplets

  def surfaces
    droplets
      .map do |droplet|
        surrounding(droplet).reject { |s| fast_droplets.include?(s) }.count
      end
      .sum
  end

  # 4126 too high
  def exterior_surfaces
    droplets
      .flat_map do |droplet|
        surrounding(droplet).reject { |s| fast_droplets.include?(s) }
      end
      .reject { |nb| air_pockets.include?(nb) }
      .count
  end

  memoize def air_pockets
    open_faces =
      droplets
        .flat_map { |d| surrounding(d) }
        .uniq
        .filter { |d| !fast_droplets.include?(d) }

    pockets = Set[]

    open_faces.each do |d|
      b = bfs([d], Set[], pockets)
      pockets += b unless b.nil?
      _debug(b: b&.size, pockets: pockets.size)
    end

    pockets
  end

  def bfs(d, visited, pockets_already)
    return visited if d.empty?
    return nil if d.any? { |di| out_of_bounds?(di) }
    return nil if d.any? { |di| pockets_already.include?(di) }

    search =
      d
        .flat_map { |d| surrounding(d) }
        .uniq
        .filter { |s| !visited.include?(s) }
        .filter { |s| !fast_droplets.include?(s) }

    bfs(search, visited + d, pockets_already)
  end

  def out_of_bounds?(point)
    x, y, z = point
    xl, xh, yl, yh, zl, zh = bounds

    x < xl || x > xh || y < yl || y > yh || z < zl || z > zh
  end

  memoize def bounds
    xl, xh = droplets.map(&:first).minmax
    yl, yh = droplets.map(&:second).minmax
    zl, zh = droplets.map(&:third).minmax
    [xl, xh, yl, yh, zl, zh]
  end

  def surrounding(side)
    # _debug(side:)
    normalize(side, SIDES)
  end

  def normalize(droplet, nbs)
    nbs.map do |nb|
      x, y, z = droplet
      nx, ny, nz = nb

      [x - nx, y - ny, z - nz]
    end
  end

  memoize def fast_droplets
    droplets.to_set
  end

  class << self
    def parse(text)
      new(
        droplets: text.gsub(",", " ").split.each_slice(3).to_a.sub_map(&:to_i)
      )
    end
  end
end
