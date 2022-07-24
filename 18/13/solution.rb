
PathElement = Struct.new(:x, :y, :type)
Cart = Struct.new(:x, :y, :direction, :next_turn)

class Cart
  def initialize(x, y, direction, next_turn = :counter_clockwise)
    self.x = x
    self.y = y
    self.direction = direction
    self.next_turn = next_turn
  end

  def update_turn
    case next_turn
    when :clockwise
      :counter_clockwise
    when :counter_clockwise
      :straight
    when :straight
      :clockwise
    else
      raise "Unknown turn: #{self}"
    end
  end

  def location
    [x, y]
  end

  def turn
    case [next_turn, direction]
    when [:clockwise, :up]
      :right
    when [:clockwise, :right]
      :down
    when [:clockwise, :down]
      :left
    when [:clockwise, :left]
      :up
    when [:counter_clockwise, :up]
      :left
    when [:counter_clockwise, :right]
      :up
    when [:counter_clockwise, :down]
      :right
    when [:counter_clockwise, :left]
      :down
    else
      direction
    end
  end
end

class Track
  attr_reader :carts, :path
  def initialize(path, carts)
    @path = path
    @carts = carts
  end

  def self.parse(text)
    Parser.new(text).parse
  end

  def first_collision
    state = self
    until state.collisions.any?
      state = state.tick
    end

    state.collisions
  end

  def collisions
    @carts.map { |ct| [ct.x, ct.y] }
      .group_by(&:itself)
      .filter { |location, carts| carts.size > 1 }
      .map(&:first)
  end

  def tick
    track = self

    for mover in @carts.sort_by(&:x).sort_by(&:y)
      track = Track.new(
        @path,
        track.carts.map { |cart| cart == mover ? next_position(cart) : cart }
      )

      return track if track.collisions.any?
    end

    track
  end

  def next_position(cart)
    x, y = next_location(cart)
    Cart.new(x, y, delta_direction(cart), update_turn(cart))
  end

  def next_location(cart)
    [
      cart.x + delta_x(cart),
      cart.y + delta_y(cart),
    ]
  end

  def delta_x(cart)
    case cart.direction
    when :up, :down
      0
    when :right
      +1
    when :left
      -1
    end
  end

  def delta_y(cart)
    case cart.direction
    when :right, :left
      0
    when :up
      -1
    when :down
      +1
    end
  end

  def update_turn(cart)
    x, y = next_location(cart)
    if @path[[x,y]]&.type == :intersection
      cart.update_turn
    else
      cart.next_turn
    end
  end

  def delta_direction(cart)
    x, y = next_location(cart)
    case @path[[x,y]]&.type
    when :vertical, :horizontal
      return cart.direction
    when :left_turn
      case cart.direction
      when :up
        return :left
      when :right
        return :down
      when :left
        return :up
      when :down
        return :right
      end
    when :right_turn
      case cart.direction
      when :up
        return :right
      when :right
        return :up
      when :left
        return :down
      when :down
        return :left
      end
    when :intersection
      return cart.turn
    end

    raise "Unknown next direction for #{cart}"
  end

  def show
    puts 0.upto(@path.values.map(&:y).max).map { |y|
      0.upto(@path.values.map(&:x).max).map { |x|
        if collisions.include?([x, y])
          'X'
        elsif cart_at(x, y)
          cart_at(x, y)
        else
          path_at(x, y)
        end
      }.join
    }.join("\n")
  end

  def cart_at(x, y)
    case @carts.find { |cart| cart.x == x && cart.y == y }&.direction
    when :up
      ?^
    when :right
      ?>
    when :down
      ?v
    when :left
      ?<
    end
  end

  def path_at(x, y)
    case @path[[x,y]]&.type
    when :vertical
      ?|
    when :horizontal
      ?-
    when :intersection
      ?+
    when :right_turn
      ?/
    when :left_turn
      ?\\
    else
      ' '
    end
  end

  class Parser
    def initialize(text)
      @text = text
    end

    def parse
      path, carts = [], []
      grid = @text.split("\n").map { |line| line.chars }

      grid.each_with_index do |row, y|
        row.each_with_index do |char, x|
          case char
          when ?|
            path << PathElement[x, y, :vertical]
          when ?-
            path << PathElement[x, y, :horizontal]
          when ?+
            path << PathElement[x, y, :intersection]
          when ?/
            path << PathElement[x, y, :right_turn]
          when ?\\
            path << PathElement[x, y, :left_turn]
          when ?>
            path << PathElement[x, y, :horizontal]
            carts << Cart[x, y, :right]
          when ?<
            path << PathElement[x, y, :horizontal]
            carts << Cart[x, y, :left]
          when ?^
            path << PathElement[x, y, :vertical]
            carts << Cart[x, y, :up]
          when ?v
            path << PathElement[x, y, :vertical]
            carts << Cart[x, y, :down]
          end
        end
      end

      Track.new(
        path.group_by { |pe| [pe.x, pe.y] }.map { |k,v| [k, v.first] }.to_h,
        carts
      )
    end
  end
end

@example = File.read('18/13/example.txt')
@input = File.read('18/13/input.txt')