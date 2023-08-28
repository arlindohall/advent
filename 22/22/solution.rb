$_debug = true

def solve(input) =
  [
    MonkeyMap.parse(input || read_input(strip: false)).final_password,
    CubeMap.parse(input || read_input(strip: false)).final_password
  ]

class MonkeyMap
  RIGHT_TURN_MATRIX = [[0, -1], [1, 0]]
  LEFT_TURN_MATRIX = [[0, 1], [-1, 0]]

  shape :map, :path

  class Map
    shape :points

    def self.parse(text)
      points = Hash.new
      text
        .split("\n")
        .each_with_index do |line, y|
          line.chars.each_with_index do |char, x|
            points[[x, y]] = char unless char.match(/\s/)
          end
        end

      new(points: points)
    end

    def barrier?(location)
      points[location] == "#"
    end

    memoize def row_bounds
      rows = points.keys.group_by(&:last)
      rows.transform_values { |points| points.map(&:first).minmax }
    end

    memoize def col_bounds
      cols = points.keys.group_by(&:first)
      cols.transform_values { |points| points.map(&:last).minmax }
    end
  end

  class Direction
    shape :turn, :distance

    def rotate(vector)
      case turn
      when :left
        LEFT_TURN_MATRIX
      when :right
        RIGHT_TURN_MATRIX
      else
        raise "Invalid turn #{self}"
      end.matrix_multiply(vector.to_vector).flatten
    end
  end

  class << self
    def parse(text)
      new(
        map: Map.parse(text.split("\n\n").first),
        path: path(text.split("\n\n").second.strip)
      )
    end

    def path(text)
      text = text.chars
      result = [Direction.new(distance: read_distance(text))]
      until text.empty?
        turn = read_turn(text)
        distance = read_distance(text)
        result << Direction.new(turn:, distance:)
      end
      result
    end

    private

    def read_turn(text)
      case text.shift
      when "L"
        :left
      when "R"
        :right
      else
        raise "Invalid turn #{text}"
      end
    end

    def read_distance(text)
      distance = []
      distance << text.shift while text.first =~ /\d/
      distance.join.to_i
    end
  end

  def final_password
    @heading = [1, 0]
    @location = top_left

    follow_path!

    password
  end

  def top_left
    [map.row_bounds[0].first, 0]
  end

  def follow_path!
    @path.each do |direction|
      @heading = direction.rotate(@heading) if direction.turn
      move(direction.distance)
      debug
    end
  end

  def move(distance)
    distance.times do
      visit
      return if barrier?

      @location = advance
    end
  end

  def visit
    @visited ||= {}
    @visited[@location] = case @heading
    when [1, 0]
      ">"
    when [0, -1]
      "^"
    when [-1, 0]
      "<"
    when [0, 1]
      "v"
    end
  end

  def barrier?
    map.barrier?(advance)
  end

  def advance
    x, y = @location
    dx, dy = @heading
    naive = [x + dx, y + dy]

    return naive if in_bounds?(naive)

    case @heading
    when [1, 0]
      [map.row_bounds[y].first, y]
    when [-1, 0]
      [map.row_bounds[y].last, y]
    when [0, 1]
      [x, map.col_bounds[x].first]
    when [0, -1]
      [x, map.col_bounds[x].last]
    else
      raise "Invalid heading #{@heading}"
    end
  end

  def in_bounds?(location)
    x, y = location

    case @heading
    when [1, 0], [-1, 0]
      xmin, xmax = map.row_bounds[y]
      xmin <= x && x <= xmax
    when [0, 1], [0, -1]
      ymin, ymax = map.col_bounds[x]
      ymin <= y && y <= ymax
    else
      raise "Invalid heading #{@heading}"
    end
  end

  def password
    r = row + 1
    c = column + 1
    _debug("Password", r:, c:, facing:)
    1000 * r + 4 * c + facing
  end

  def row
    @location.second
  end

  def column
    @location.first
  end

  def facing
    case @heading
    when [1, 0]
      0
    when [0, -1]
      1
    when [-1, 0]
      2
    when [0, 1]
      3
    end
  end

  def debug
    return unless $_debug

    _debug(
      "Bounds",
      col: map.col_bounds,
      row: map.row_bounds,
      location: @location
    )

    ymin, ymax = map.col_bounds.values.flatten.minmax
    xmin, xmax = map.row_bounds.values.flatten.minmax

    _debug("Printing", xmin:, xmax:, ymin:, ymax:)

    ymin.upto(ymax) do |y|
      xmin.upto(xmax) do |x|
        print @visited[[x, y]] || map.points[[x, y]] || " "
      end
      puts
    end
  end
end

class CubeMap < MonkeyMap
  class Face
    shape :original_location, :orientation, :points
  end

  class Cube
    shape :faces, :size, faces: {}

    RIGHT_TURN_MATRIX = [[0, 0, 1], [0, 1, 0], [-1, 0, 0]].transpose
    LEFT_TURN_MATRIX = [[0, 0, -1], [0, 1, 0], [1, 0, 0]].transpose
    UP_TURN_MATRIX = [[1, 0, 0], [0, 0, -1], [0, 1, 0]].transpose
    DOWN_TURN_MATRIX = [[1, 0, 0], [0, 0, 1], [0, -1, 0]].transpose

    def contains(face_location)
      faces.values.compact.any? { |f| f.original_location == face_location }
    end

    def barrier?(location)
      faces[:front].points[location] == "#"
    end

    def add_face(original_location, points)
      raise "Already a face here" if faces[:front]
      faces[:front] = Face.new(
        original_location: original_location,
        orientation: basis,
        points: points
      )
    end

    def front_is?(origin)
      faces[:front].original_location == origin
    end

    def position_on_map(location)
      rx, ry, _ = faces[:front].orientation.flatten
      dx, dy = faces[:front].original_location

      x, y = location

      x = (x * rx) % 50 + dx
      y = (y * ry) % 50 + dy

      [x, y]
    end

    def rotate_right
      turn(
        {
          front: faces[:left],
          right: faces[:front],
          back: faces[:right],
          left: faces[:back],
          top: faces[:top],
          bottom: faces[:bottom]
        },
        RIGHT_TURN_MATRIX
      )
    end

    def rotate_left
      turn(
        {
          front: faces[:right],
          right: faces[:back],
          back: faces[:left],
          left: faces[:front],
          top: faces[:top],
          bottom: faces[:bottom]
        },
        LEFT_TURN_MATRIX
      )
    end

    def rotate_down
      turn(
        {
          front: faces[:top],
          bottom: faces[:front],
          back: faces[:bottom],
          top: faces[:back],
          left: faces[:left],
          right: faces[:right]
        },
        DOWN_TURN_MATRIX
      )
    end

    def rotate_up
      turn(
        {
          front: faces[:bottom],
          bottom: faces[:back],
          back: faces[:top],
          top: faces[:front],
          left: faces[:left],
          right: faces[:right]
        },
        UP_TURN_MATRIX
      )
    end

    def turn(faces, matrix)
      Cube[
        size: size,
        faces:
          faces.transform_values do |face|
            next nil unless face

            Face[
              original_location: face.original_location,
              orientation: matrix.matrix_multiply(face.orientation),
              points: face.points
            ]
          end
      ]
    end

    def basis
      [1, 1, 0].to_vector
    end

    def debug
      points = {}
      cube = self

      4.times do
        points.merge!(cube.transpose_front)
        cube = cube.rotate_right
      end

      4.times do
        points.merge!(cube.transpose_front)
        cube = cube.rotate_down
      end

      show_from(points)
    end

    def transpose_front
      points = {}
      tx, ty, _tz = faces[:front].orientation.flatten
      faces[:front].points.each do |(x, y), value|
        points[[(x * tx) % size, (y * ty) % size]] = value
      end
    end

    def show_from(points)
      0.upto(4 * size) do |y|
        0.upto(4 * size) { |x| print points[[x, y]] || " " }
        puts
      end
    end
  end

  def move(distance)
    distance.times do
      visit
      return if barrier?

      @location, @cube = advance
    end
  end

  def visit
    @visited ||= {}

    x, y = cube.position_on_map(@location)

    @visited[[x, y]] = case @heading
    when [1, 0]
      ">"
    when [0, -1]
      "^"
    when [-1, 0]
      "<"
    when [0, 1]
      "v"
    end
  end

  def barrier?
    location, cube = advance

    cube.barrier?(location)
  end

  def advance
    x, y = @location
    dx, dy = @heading
    naive = [x + dx, y + dy]

    return naive, cube if in_bounds?(naive)

    rotate_and_advance(naive)
  end

  def in_bounds?(point)
    x, y = point

    0 <= x && x < cube_size && 0 <= y && y < cube_size
  end

  def rotate_and_advance(point)
    x, y = point

    if (x < 0 || x >= cube_size) && (y < 0 || y >= cube_size)
      raise "Impossible move around corner"
    end

    if (x >= 0 && x < cube_size) && (y >= 0 && y < cube_size)
      raise "Should not rotate because move in bounds"
    end

    if x < 0
      [[cube_size - 1, y], cube.rotate_right]
    elsif x >= cube_size
      [[0, y], cube.rotate_left]
    elsif y < 0
      [[x, cube_size - 1], cube.rotate_down]
    elsif y >= cube_size
      [[x, 0], cube.rotate_up]
    end
  end

  def top_left
    build_cube
    rotate_to_top_left
    [0, 0]
  end

  def build_cube
    parse_face([map.row_bounds[0].first, 0])
  end

  def rotate_to_top_left
    origin = [map.row_bounds[0].first, 0]

    4.times do
      return if cube.front_is?(origin)
      @cube = cube.rotate_left
    end

    4.times do
      return if cube.front_is?(origin)
      @cube = cube.rotate_up
    end

    raise "Cannot find top left corner"
  end

  def parse_face(face_start)
    return if cube.contains(face_start)

    cube.add_face(face_start, points_from(face_start))

    if cube_to_left(face_start)
      rotate(:right)
      parse_face(cube_to_left(face_start))
      rotate(:left)
    end

    if cube_to_right(face_start)
      rotate(:left)
      parse_face(cube_to_right(face_start))
      rotate(:right)
    end

    if cube_to_bottom(face_start)
      rotate(:up)
      parse_face(cube_to_bottom(face_start))
      rotate(:down)
    end

    if cube_to_top(face_start)
      rotate(:down)
      parse_face(cube_to_top(face_start))
      rotate(:up)
    end

    cube
  end

  def rotate(direction)
    @cube =
      case direction
      when :left
        cube.rotate_left
      when :right
        cube.rotate_right
      when :up
        cube.rotate_up
      when :down
        cube.rotate_down
      else
        raise ArgumentError, "Unknown direction #{direction}"
      end
  end

  def cube_to_left(face_start)
    x, y = face_start
    cube_face_at([x - cube_size, y])
  end

  def cube_to_right(face_start)
    x, y = face_start
    cube_face_at([x + cube_size, y])
  end

  def cube_to_bottom(face_start)
    x, y = face_start
    cube_face_at([x, y + cube_size])
  end

  def cube_to_top(face_start)
    x, y = face_start
    cube_face_at([x, y - cube_size])
  end

  def cube_face_at(point)
    point if map.points.key?(point)
  end

  def points_from(face_start)
    x, y = face_start
    points = {}

    0.upto(cube_size - 1) do |py|
      0.upto(cube_size - 1) do |px|
        tx, ty = x + px, y + py
        points[[tx, ty]] = map.points[[tx, ty]]
      end
    end

    points
  end

  def cube
    @cube ||= Cube.new(size: cube_size)
  end

  def row
    x, _y = cube.position_on_map(@location)
    x
  end

  def column
    _x, y = cube.position_on_map(@location)
    y
  end

  memoize def cube_size
    Math.sqrt(map.points.count / 6).to_i
  end
end
