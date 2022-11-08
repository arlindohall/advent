$debug = true

require 'set'

require_relative '../intcode'

class TractorBeam
  def initialize(program)
    @program = program
  end

  def points
    0.upto(49).flat_map do |y|
      0.upto(49).map do |x|
        is_pulled?(x, y)
      end
    end.sum
  end

  def debug
    0.upto(49).each do |y|
      0.upto(49).each do |x|
        print is_pulled?(x, y) == 1 ? '#' : '.'
      end
      puts
    end
  end

  def smallest_square
    # Found with debug
    # First continous point where is_pulled? true, doesn't constrict to one point
    queue = [[4, 15]]

    loop do
      puts "queue_size/#{queue.size}, point/#{queue.first}" if $debug
      queue = queue.flat_map { |pt| neighbors(pt) }.uniq
      winners = queue.filter { |x, y| can_fit_square?(x, y) }
      return calculate_answer(winners.first) if winners.any?
    end
  end

  def calculate_answer(point)
    x, y = point
    10_000 * x + y
  end

  def neighbors(point)
    x, y = point
    [
      [x+1, y],
      [x, y+1],
      # [x+1, y+1],
    ].filter { |x, y| is_pulled?(x, y) == 1 }
     .reject { |x, y| visited?(x, y) }
  end

  def visited?(x, y)
    @visited ||= Set.new
    return false unless @visited.include?([x,y])
    @visited << [x,y]
  end

  def can_fit_square?(x, y)
    @answer ||= {}
    return @answer[[x,y]] if @answer[[x,y]]

    @answer[[x,y]] = [
      [x, y],
      [x+99, y],
      [x, y+99],
    ].all? { |x, y| is_pulled?(x, y) == 1 }
  end

  def is_pulled?(x, y)
    @grid ||= {}
    return @grid[[x,y]] if @grid[[x,y]]
    puts "Calculating (#{x},#{y}) dist/#{x+y} grid_size/#{@grid.size}" if $debug && @grid.size % 1000 == 0

    points = @program.dup
      .tap { |pgm| pgm.send_signal(x) }
      .tap { |pgm| pgm.send_signal(y) }
      .tap { |pgm| pgm.interpret! }
      .receive_signals

    raise "Unexpected output" unless points.size == 1

    @grid[[x,y]] = points.first
  end

  class << self
    def parse(text)
      new(IntcodeProgram.parse(text))
    end
  end
end

def solve
  [
    TractorBeam.parse(@input).points,
    TractorBeam.parse(@input).smallest_square,
  ]
end

@input = <<-input.strip
109,424,203,1,21101,11,0,0,1105,1,282,21102,18,1,0,1105,1,259,2102,1,1,221,203,1,21102,1,31,0,1106,0,282,21101,0,38,0,1106,0,259,20102,1,23,2,21202,1,1,3,21101,0,1,1,21102,57,1,0,1105,1,303,2101,0,1,222,20102,1,221,3,20101,0,221,2,21102,259,1,1,21101,0,80,0,1106,0,225,21102,135,1,2,21101,0,91,0,1105,1,303,2102,1,1,223,21001,222,0,4,21102,259,1,3,21102,1,225,2,21101,0,225,1,21101,118,0,0,1106,0,225,20101,0,222,3,21101,0,12,2,21101,0,133,0,1106,0,303,21202,1,-1,1,22001,223,1,1,21102,1,148,0,1105,1,259,1202,1,1,223,21002,221,1,4,20102,1,222,3,21101,0,17,2,1001,132,-2,224,1002,224,2,224,1001,224,3,224,1002,132,-1,132,1,224,132,224,21001,224,1,1,21102,1,195,0,105,1,109,20207,1,223,2,21001,23,0,1,21101,0,-1,3,21101,214,0,0,1105,1,303,22101,1,1,1,204,1,99,0,0,0,0,109,5,1202,-4,1,249,21201,-3,0,1,22102,1,-2,2,22102,1,-1,3,21102,250,1,0,1106,0,225,21202,1,1,-4,109,-5,2106,0,0,109,3,22107,0,-2,-1,21202,-1,2,-1,21201,-1,-1,-1,22202,-1,-2,-2,109,-3,2105,1,0,109,3,21207,-2,0,-1,1206,-1,294,104,0,99,21201,-2,0,-2,109,-3,2105,1,0,109,5,22207,-3,-4,-1,1206,-1,346,22201,-4,-3,-4,21202,-3,-1,-1,22201,-4,-1,2,21202,2,-1,-1,22201,-4,-1,1,22102,1,-2,3,21101,0,343,0,1106,0,303,1105,1,415,22207,-2,-3,-1,1206,-1,387,22201,-3,-2,-3,21202,-2,-1,-1,22201,-3,-1,3,21202,3,-1,-1,22201,-3,-1,2,22101,0,-4,1,21102,384,1,0,1105,1,303,1106,0,415,21202,-4,-1,-4,22201,-4,-3,-4,22202,-3,-2,-2,22202,-2,-4,-4,22202,-3,-2,-3,21202,-4,-1,-2,22201,-3,-2,1,22102,1,1,-4,109,-5,2106,0,0
input