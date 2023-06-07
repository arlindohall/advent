def solve =
  read_input.then do |it|
    [Bridge.parse(it).tail_visited, Bridge.parse(it).ten_tail_visited]
  end

class Bridge
  shape :rope, :moves, rope: :"Rope.new"

  def tail_visited
    tails = Set.new
    moves.each do |m, t|
      t.times do
        rope.move!(m)
        tails << rope.tail.dup
        # rope.debug
        # debug(tails)
      end
    end

    tails.count
  end

  # too small: 2387
  # too big: 3515
  def ten_tail_visited
    tails = Set.new
    ropes = 10.times.map { Rope.new }

    moves.each do |first_move, t|
      t.times do
        move = first_move
        ropes.each { |rope| move = rope.move!(move) }
        tails << ropes.last.head.dup
      end
      # debug_chain(ropes)
    end

    tails.count
  end

  def debug_chain(chain)
    chain = chain.map(&:head)
    # xmin, xmax = chain.map(&:first).minmax
    # ymin, ymax = chain.map(&:second).minmax

    18
      .downto(-7)
      .each do |y|
        -14
          .upto(16)
          .each do |x|
            print(chain.include?([x, y]) ? chain.index([x, y]) : ".")
          end
        puts
      end
    puts
  end

  def debug(squares)
    xmin, xmax = squares.map(&:first).minmax
    ymin, ymax = squares.map(&:second).minmax

    # _debug(squares)
    ymax
      .downto(ymin)
      .each do |y|
        xmin.upto(xmax).each { |x| print(squares.include?([x, y]) ? "X" : ".") }
        puts
      end
    puts
  end

  class << self
    def parse(text)
      new(
        moves:
          text.split.each_slice(2).map { |dir, count| [delta(dir), count.to_i] }
      )
    end

    def delta(direction)
      case direction
      when "R"
        [1, 0]
      when "L"
        [-1, 0]
      when "U"
        [0, 1]
      when "D"
        [0, -1]
      end
    end
  end
end

class Rope
  shape :head, :tail, head: [0, 0], tail: [0, 0]

  def move!(move)
    dx, dy = move

    # _debug(dx:, dy:, head:, tail:)
    @head = @head.then { |x, y| [x + dx, y + dy] }

    otx, oty = tail.dup

    reconcile_tail!

    tx, ty = tail

    [tx - otx, ty - oty]
  end

  def reconcile_tail!
    return if touching?(head, tail)

    hx, hy = head
    tx, ty = tail

    tail[0] = tx + (hx <=> tx) if hx != tx
    tail[1] = ty + (hy <=> ty) if hy != ty
  end

  def touching?(a, b)
    ax, ay = a

    neighbors(ax, ay).include?(b)
  end

  def neighbors(x, y)
    [
      [x + 1, y],
      [x - 1, y],
      [x, y + 1],
      [x, y - 1],
      [x + 1, y + 1],
      [x - 1, y - 1],
      [x + 1, y - 1],
      [x - 1, y + 1],
      [x, y]
    ]
  end

  def debug
    5.downto(0) do |y|
      0.upto(5) do |x|
        if [x, y] == head
          print "H"
        elsif [x, y] == tail
          print "T"
        else
          print "."
        end
      end
      puts
    end
    puts
  end
end
