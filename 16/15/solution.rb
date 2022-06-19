

class Sculpture
  def initialize(discs)
    @discs = discs.strip.lines.map(&:strip).map{|l| Disc.parse(l)}
    @time = 0
    @balls = []
  end

  def find_opening
    until winning_ball?
      tick
    end

    @time - @discs.size
  end

  def winning_ball?
    @balls.filter do |ball|
      ball.height == @discs.size
    end.filter do |ball|
      disc_at(ball.height).open?
    end.any?
  end

  def disc_at(height)
    @discs[height-1]
  end

  def tick
    add_ball_at_top
    increment_time
    spin_discs
    update_balls
  end

  def add_ball_at_top
    @balls << Ball.new
  end

  def increment_time
    @time += 1
  end

  def spin_discs
    @discs = @discs.map{|d| d.tick}
  end

  def update_balls
    @balls = @balls.map(&:tick)
      .filter{|b| disc_at(b.height).open?}
  end
end

class Ball
  def initialize(height = 0)
    @height = height
  end

  def tick
    Ball.new(@height + 1)
  end

  def height
    @height
  end
end

class Disc
  def initialize(size, position)
    @size = size
    @position = position
  end

  def tick
    Disc.new(@size, (@position + 1) % @size)
  end

  def open?
    @position == 0
  end

  def self.parse(string)
    Disc.new(
      /(\d+) positions/.match(string)[1].to_i,
      /position (\d+)/.match(string)[1].to_i,
    )
  end
end

@example = "
Disc #1 has 5 positions; at time=0, it is at position 4.
Disc #2 has 2 positions; at time=0, it is at position 1.
"

@input = "
Disc #1 has 17 positions; at time=0, it is at position 1.
Disc #2 has 7 positions; at time=0, it is at position 0.
Disc #3 has 19 positions; at time=0, it is at position 2.
Disc #4 has 5 positions; at time=0, it is at position 0.
Disc #5 has 3 positions; at time=0, it is at position 0.
Disc #6 has 13 positions; at time=0, it is at position 5.
"

@part2 = @input + "11 positions; position 0."