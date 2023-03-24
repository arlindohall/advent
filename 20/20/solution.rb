def solve
  [
    PhotoArray.new(read_input).border_product,
    PhotoArray.new(read_input).roughness
  ]
end

class PhotoArray < Struct.new(:text)
  def photos
    @photos ||= text.split("\n\n").map { Photo.new(_1) }
  end

  def border_product
    corners.map(&:metadata).reduce(&:*)
  end

  def roughness
    picture_matrix.flatten.count { |ch| ch == "#" } - (monsters * monster_size)
  end

  # private

  attr_reader :grid_size, :full_image, :current_row, :remaining_photos

  def monsters
    possible_final_images.map { |image| count_monsters(image) }.max
  end

  def picture_matrix
    @picture_matrix ||=
      trimmed_arrangement
        .map { |row| splice_columns(row) } # Array of arrays of rows
        .flatten(1) # 2D matrix of pixels
  end

  def trimmed_arrangement
    correct_arrangement # 2D matrix of photos
      .sub_map { |segment| trim_segment(segment) }
  end

  def trim_segment(segment)
    size = segment.size
    # _debug("trimming segment", size:, segment:)
    segment.take(size - 1).drop(1).map { |row| row.take(size - 1).drop(1) }
  end

  def splice_columns(row)
    row.first.each_index.map do |index|
      row
        .map { |sub_image| sub_image[index] } # same row in each sub-image
        .reduce(&:+) # join rows together
    end
  end

  def correct_arrangement
    @grid_size = Math.sqrt(photos.size)
    @full_image = []
    @current_row = []
    @remaining_photos = photos
    align
  end

  def align
    # _debug(full_image_size: full_image.size, current_row_size: current_row.size,
    #   remaining_photo_size: remaining_photos.size)
    if remaining_photos.empty? && current_row.empty?
      raise "Wrong guard clause caught"
    end
    return full_image.with(current_row) if remaining_photos.empty?

    if current_row.size == grid_size
      full_image << current_row
      @current_row = []
      return align
    end

    if current_row.empty?
      corner, orientation = corner_for(full_image, remaining_photos)
      current_row << orientation
      remaining_photos.without!(corner)
      return align
    end

    segment, orientation = next_segment(current_row, remaining_photos)
    current_row << orientation
    remaining_photos.without!(segment)
    align
  end

  def corner_for(full_image, remaining_photos)
    # _debug(full_image_size: full_image.size, remaining_photo_size: remaining_photos.size)
    return any_corner if full_image.empty?

    bs = full_image.last.first.last

    photo =
      remaining_photos
        .filter do |photo|
          photo.orientations.map(&:first).any? { |row| row == bs }
        end
        .only!

    orientation =
      photo.orientations.filter { |orientation| orientation.first == bs }.only!

    return photo, orientation
    # .plopp
  end

  def any_corner
    corners.first.then { |cn| [cn, orient_first_corner(cn)] }
  end

  def orient_first_corner(corner)
    corner
      .orientations
      .filter { |ot| bottom_matches?(corner, ot) && right_matches?(corner, ot) }
      .first # will be exactly two, transpose of one another
  end

  def bottom_matches?(corner, orientation)
    bottom = orientation.last
    photos
      .without(corner)
      .flat_map(&:borders)
      .any? { |border| border == bottom }
  end

  def right_matches?(corner, orientation)
    right = right_side(orientation)
    photos.without(corner).flat_map(&:borders).any? { |border| border == right }
  end

  def next_segment(current_row, remaining_photos)
    rs = right_side(current_row.last)

    photo =
      remaining_photos
        .filter do |photo|
          photo.orientations.map { |seg| top(seg) }.any? { |row| row == rs }
        end
        .only!

    orientation =
      photo
        .orientations
        .filter { |orientation| left_side(orientation) == rs }
        .only!
    # .then { |matrix| 3.times { matrix = matrix.matrix_rotate } ; matrix }

    return photo, orientation
    # .plopp
  end

  def right_side(segment)
    segment.map(&:last)
  end

  def left_side(segment)
    segment.map(&:first)
  end

  def top(segment)
    segment.first
  end

  def bottom(segment)
    segment.last
  end

  def possible_final_images
    rotations(picture_matrix)
  end

  def rotations(image)
    [
      image.matrix_rotate(0),
      image.matrix_rotate(1),
      image.matrix_rotate(2),
      image.matrix_rotate(3),
      image.reverse.matrix_rotate(0),
      image.reverse.matrix_rotate(1),
      image.reverse.matrix_rotate(2),
      image.reverse.matrix_rotate(3)
    ]
  end

  def count_monsters(image)
    image
      .each_index
      .flat_map { |y| image[y].each_index.map { |x| monster_at(x, y, image) } }
      .filter(&:itself)
      .count
  end

  def monster_at(x, y, image)
    # _debug(shape: image.shape, pixel: image[y][x])
    monster_coords.all? do |mx, my|
      image[my + y] && image[my + y][mx + x] == "#"
    end
  end

  def monster
    @monster ||= [
      "                  # ",
      "#    ##    ##    ###",
      " #  #  #  #  #  #   "
    ]
  end

  def monster_coords
    @monster_coords ||=
      monster
        .each_with_index
        .flat_map do |row, y|
          row.chars.each_with_index.map { |ch, x| [x, y] if ch == "#" }
        end
        .compact
  end

  def monster_size
    monster_coords.size
  end

  def corners
    photos_bordering(2)
  end

  def sides
    photos_bordering(3)
  end

  def photos_bordering(n)
    photos.filter do |photo|
      borders = borders_except(photo)
      photo.borders.take(4).count { |bd| borders.include?(bd) } == n
    end
  end

  def borders_except(photo)
    photos.without(photo).flat_map(&:borders)
  end

  class Photo < Struct.new(:full)
    def trim
      raise "Remove the edges of the image and return array"
    end

    def metadata
      full.split.second.split(":").first.to_i
    end

    def borders
      @borders ||= orientations.map(&:first)
    end

    def orientations
      @orientations ||= [
        rotate(0),
        rotate(1),
        rotate(2),
        rotate(3),
        rotate(0, tile.reverse),
        rotate(1, tile.reverse),
        rotate(2, tile.reverse),
        rotate(3, tile.reverse)
      ]
    end

    def rotate(n, tiles = nil)
      tiles ||= tile
      n.times { tiles = tiles.matrix_rotate }

      tiles
    end

    def tile
      @tile ||= full.split("\n").drop(1).map(&:chars)
    end

    def show!(rotations = 0)
      puts rotate(rotations).sub_map(&:darken_squares).map(&:join).join("\n")
    end
  end
end
