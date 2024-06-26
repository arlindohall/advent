$_debug = false

require_relative "../intcode"

class ASCII
  # Gotten through experimentation
  SEGMENT1 = "R,10,L,8,R,10,R,4"
  SEGMENT2 = "L,6,L,6,R,10"
  SEGMENT3 = "L,6,R,12,R,12,R,10"

  def initialize(program)
    @program = program
  end

  def dup
    ASCII.new(@program.dup)
  end

  def initial_scaffold
    @initial_scaffold ||=
      (
        @program.interpret!
        @program.receive_signals.pack("c*")
      )
  end

  def scaffold
    Scaffold.parse(initial_scaffold)
  end

  def dust
    input = dup.program_input
    machine = @program.dup
    machine.override!(0, 2)

    input = <<~input
    #{input}
    #{movement_functions}
    n
    input

    puts input

    input.chars.each { |ch| machine.send_signal(ch.ord) }
    machine.interpret!

    # Why doesn't this work when I send 'n'?

    signals = machine.receive_signals
    puts signals.filter { |s| s < 128 }.pack("c*")
    return signals.last.plop
  end

  def dust_debug
    input = dup.program_input
    machine = @program.dup
    machine.override!(0, 2)

    input = <<~input
    #{input}
    #{movement_functions}
    y
    input

    puts input

    input.chars.each { |ch| machine.send_signal(ch.ord) }
    machine.interpret!(_debug: true)

    # Why doesn't this work when I send 'n'?
    # signals =  machine.receive_signals
    # puts signals.pack('c*')
    # puts signals.last
  end

  # I confirmed that my input on other peoples' solutions actually produces
  # 10 when you input 'n', but the right answer when you input 'y', so I'm
  # going to just get over it and move on.
  def dust_wtf
    input = dup.program_input
    @input_chars = <<~input
    #{input}
    #{movement_functions}
    n



    input

    machine = @program.dup
    machine.override!(0, 2)
    machine.start!

    until machine.done?
      machine.send_signal(read_char_wtf) if machine.reading?
      print machine.receive_signals.pack("c*") if machine.writing?
      machine.continue!
    end
  end

  def read_char_wtf
    @input_char_index ||= 0
    raise "WTF out of bounds on input" if @input_char_index >= @input_chars.size
    print @input_chars[@input_char_index]
    @input_chars[@input_char_index].ord
  ensure
    @input_char_index += 1
  end

  def dust_manual
    puts "Please enter at the prompt:"
    puts dup.program_input
    puts movement_functions
    puts "n"

    machine = @program.dup
    machine.override!(0, 2)
    machine.start!

    until machine.done?
      machine.send_signal(read_char) if machine.reading?
      print machine.receive_signals.pack("c*") if machine.writing?
      machine.continue!
    end
  end

  def read_char
    ch = $stdin.getch
    return ch.ord if ch != "\r"
    return "\n".ord
  end

  def program_input
    scaffold
      .path
      .join(",")
      .gsub(SEGMENT1, "A")
      .gsub(SEGMENT2, "B")
      .gsub(SEGMENT3, "C")
  end

  def movement_functions
    [SEGMENT1, SEGMENT2, SEGMENT3].join("\n")
  end

  def self.parse(input)
    new(IntcodeProgram.parse(input).dup)
  end
end

class Scaffold
  attr_reader :map
  def initialize(map)
    @map = map
    @xmax = @map.keys.map(&:first).max
    @ymax = @map.keys.map(&:last).max
  end

  def path
    return @path if @path

    @path = []
    @vacuum = @map.keys.find { |x, y| @map[[x, y]] == "^" }
    while turn
      _debug
      @path << next_step
    end

    @path
  end

  def turn
    neighbors
      .reject { |point| coming_from?(point) }
      .filter { |point| @map[point] == "#" }
      .tap { |list| raise "Cannot have multiple choices" unless list.size < 2 }
      .map { |point| to_direction(point) }
      .first
  end

  def neighbors
    x, y = @vacuum
    [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]].filter do |point|
      @map[point]
    end
  end

  def coming_from?(point)
    x, y = @vacuum
    case @map[@vacuum]
    when "^"
      point == [x, y + 1]
    when ">"
      point == [x - 1, y]
    when "v"
      point == [x, y - 1]
    when "<"
      point == [x + 1, y]
    else
      raise "Not sure how to handle #{@map[@vacuum]} (loc=#{@vacuum})"
    end
  end

  def to_direction(point)
    x, y = @vacuum
    dx, dy = point
    [dx - x, dy - y]
  end

  def next_step
    dir = turn
    turn = do_turn(dir)
    travel = do_travel(dir)

    "#{turn},#{travel}"
  end

  def do_turn(dir)
    old = @map[@vacuum]

    @map[@vacuum] = case dir
    when [0, 1]
      "v"
    when [0, -1]
      "^"
    when [-1, 0]
      "<"
    when [1, 0]
      ">"
    else
      raise "Not sure how to turn #{dir}"
    end

    case [old, @map[@vacuum]]
    when %w[^ >], %w[> v], %w[v <], %w[< ^]
      "R"
    when %w[^ <], %w[< v], %w[v >], %w[> ^]
      "L"
    else
      raise "Impossible turn old=#{old} new=#{@map[@vacuum]}"
    end
  end

  def do_travel(dir)
    x, y = @vacuum
    dx, dy = dir
    steps = 0

    until @map[[x + dx, y + dy]] != "#"
      x += dx
      y += dy
      steps += 1
    end

    @map[[x, y]] = @map[@vacuum]
    @map[@vacuum] = "#"

    @vacuum = [x, y]

    steps
  end

  def alignment_parameters
    intersections.map { |x, y| x * y }.sum
  end

  def intersections
    @map.keys.filter { |x, y| all_neighbors_scaffold?(x, y) }
  end

  def all_neighbors_scaffold?(x, y)
    [
      @map[[x, y]],
      @map[[x + 1, y]],
      @map[[x - 1, y]],
      @map[[x, y + 1]],
      @map[[x, y - 1]]
    ].all? { |c| c == "#" }
  end

  def _debug
    return unless $_debug
    print "\033[H"
    0.upto(@ymax) do |y|
      0.upto(@xmax).map { |x| print @map[[x, y]] || "." }
      print "\n"
    end
  end

  def self.parse(input)
    new(hash_representation(input))
  end

  def self.hash_representation(text)
    hash = {}
    text
      .split("\n")
      .each_with_index do |line, y|
        line.chars.each_with_index { |char, x| hash[[x, y]] = char }
      end
    hash
  end
end

def solve
  [ASCII.parse(@input).scaffold.alignment_parameters, ASCII.parse(@input).dust]
end

@input = <<-text.strip
1,330,331,332,109,3862,1101,0,1182,15,1101,1465,0,24,1002,0,1,570,1006,570,36,102,1,571,0,1001,570,-1,570,1001,24,1,24,1106,0,18,1008,571,0,571,1001,15,1,15,1008,15,1465,570,1006,570,14,21101,58,0,0,1105,1,786,1006,332,62,99,21102,333,1,1,21101,73,0,0,1105,1,579,1102,0,1,572,1102,0,1,573,3,574,101,1,573,573,1007,574,65,570,1005,570,151,107,67,574,570,1005,570,151,1001,574,-64,574,1002,574,-1,574,1001,572,1,572,1007,572,11,570,1006,570,165,101,1182,572,127,102,1,574,0,3,574,101,1,573,573,1008,574,10,570,1005,570,189,1008,574,44,570,1006,570,158,1105,1,81,21101,340,0,1,1106,0,177,21101,477,0,1,1106,0,177,21101,514,0,1,21102,1,176,0,1105,1,579,99,21102,1,184,0,1106,0,579,4,574,104,10,99,1007,573,22,570,1006,570,165,1002,572,1,1182,21102,1,375,1,21102,211,1,0,1105,1,579,21101,1182,11,1,21101,0,222,0,1105,1,979,21101,0,388,1,21102,233,1,0,1106,0,579,21101,1182,22,1,21101,0,244,0,1106,0,979,21102,1,401,1,21102,255,1,0,1105,1,579,21101,1182,33,1,21102,1,266,0,1106,0,979,21102,1,414,1,21101,0,277,0,1106,0,579,3,575,1008,575,89,570,1008,575,121,575,1,575,570,575,3,574,1008,574,10,570,1006,570,291,104,10,21101,1182,0,1,21102,313,1,0,1105,1,622,1005,575,327,1101,1,0,575,21102,327,1,0,1105,1,786,4,438,99,0,1,1,6,77,97,105,110,58,10,33,10,69,120,112,101,99,116,101,100,32,102,117,110,99,116,105,111,110,32,110,97,109,101,32,98,117,116,32,103,111,116,58,32,0,12,70,117,110,99,116,105,111,110,32,65,58,10,12,70,117,110,99,116,105,111,110,32,66,58,10,12,70,117,110,99,116,105,111,110,32,67,58,10,23,67,111,110,116,105,110,117,111,117,115,32,118,105,100,101,111,32,102,101,101,100,63,10,0,37,10,69,120,112,101,99,116,101,100,32,82,44,32,76,44,32,111,114,32,100,105,115,116,97,110,99,101,32,98,117,116,32,103,111,116,58,32,36,10,69,120,112,101,99,116,101,100,32,99,111,109,109,97,32,111,114,32,110,101,119,108,105,110,101,32,98,117,116,32,103,111,116,58,32,43,10,68,101,102,105,110,105,116,105,111,110,115,32,109,97,121,32,98,101,32,97,116,32,109,111,115,116,32,50,48,32,99,104,97,114,97,99,116,101,114,115,33,10,94,62,118,60,0,1,0,-1,-1,0,1,0,0,0,0,0,0,1,6,30,0,109,4,1202,-3,1,587,20101,0,0,-1,22101,1,-3,-3,21102,0,1,-2,2208,-2,-1,570,1005,570,617,2201,-3,-2,609,4,0,21201,-2,1,-2,1105,1,597,109,-4,2106,0,0,109,5,1202,-4,1,630,20102,1,0,-2,22101,1,-4,-4,21101,0,0,-3,2208,-3,-2,570,1005,570,781,2201,-4,-3,653,20101,0,0,-1,1208,-1,-4,570,1005,570,709,1208,-1,-5,570,1005,570,734,1207,-1,0,570,1005,570,759,1206,-1,774,1001,578,562,684,1,0,576,576,1001,578,566,692,1,0,577,577,21102,702,1,0,1106,0,786,21201,-1,-1,-1,1106,0,676,1001,578,1,578,1008,578,4,570,1006,570,724,1001,578,-4,578,21102,731,1,0,1105,1,786,1106,0,774,1001,578,-1,578,1008,578,-1,570,1006,570,749,1001,578,4,578,21102,756,1,0,1106,0,786,1106,0,774,21202,-1,-11,1,22101,1182,1,1,21102,1,774,0,1106,0,622,21201,-3,1,-3,1105,1,640,109,-5,2105,1,0,109,7,1005,575,802,20101,0,576,-6,20101,0,577,-5,1106,0,814,21101,0,0,-1,21101,0,0,-5,21102,1,0,-6,20208,-6,576,-2,208,-5,577,570,22002,570,-2,-2,21202,-5,51,-3,22201,-6,-3,-3,22101,1465,-3,-3,2102,1,-3,843,1005,0,863,21202,-2,42,-4,22101,46,-4,-4,1206,-2,924,21102,1,1,-1,1105,1,924,1205,-2,873,21101,35,0,-4,1105,1,924,1201,-3,0,878,1008,0,1,570,1006,570,916,1001,374,1,374,1202,-3,1,895,1101,0,2,0,2101,0,-3,902,1001,438,0,438,2202,-6,-5,570,1,570,374,570,1,570,438,438,1001,578,558,921,21002,0,1,-4,1006,575,959,204,-4,22101,1,-6,-6,1208,-6,51,570,1006,570,814,104,10,22101,1,-5,-5,1208,-5,47,570,1006,570,810,104,10,1206,-1,974,99,1206,-1,974,1101,1,0,575,21101,0,973,0,1105,1,786,99,109,-7,2106,0,0,109,6,21101,0,0,-4,21101,0,0,-3,203,-2,22101,1,-3,-3,21208,-2,82,-1,1205,-1,1030,21208,-2,76,-1,1205,-1,1037,21207,-2,48,-1,1205,-1,1124,22107,57,-2,-1,1205,-1,1124,21201,-2,-48,-2,1106,0,1041,21101,0,-4,-2,1105,1,1041,21101,-5,0,-2,21201,-4,1,-4,21207,-4,11,-1,1206,-1,1138,2201,-5,-4,1059,2101,0,-2,0,203,-2,22101,1,-3,-3,21207,-2,48,-1,1205,-1,1107,22107,57,-2,-1,1205,-1,1107,21201,-2,-48,-2,2201,-5,-4,1090,20102,10,0,-1,22201,-2,-1,-2,2201,-5,-4,1103,1201,-2,0,0,1106,0,1060,21208,-2,10,-1,1205,-1,1162,21208,-2,44,-1,1206,-1,1131,1106,0,989,21101,439,0,1,1106,0,1150,21101,0,477,1,1105,1,1150,21101,514,0,1,21102,1,1149,0,1106,0,579,99,21101,0,1157,0,1106,0,579,204,-2,104,10,99,21207,-3,22,-1,1206,-1,1138,2101,0,-5,1176,2101,0,-4,0,109,-6,2106,0,0,4,13,38,1,11,1,38,1,11,1,38,1,11,1,38,1,11,1,38,1,11,1,34,5,11,1,15,13,6,1,15,1,15,1,11,1,6,1,15,1,15,1,11,1,6,1,15,1,15,1,11,1,6,1,15,1,15,1,11,1,6,1,15,1,15,1,11,1,6,1,5,11,15,1,11,1,6,1,31,1,11,1,6,1,31,1,11,1,6,1,31,1,11,1,6,9,23,1,1,11,14,1,23,1,1,1,24,1,23,7,20,1,25,1,3,1,20,1,9,7,7,11,16,1,9,1,5,1,7,1,1,1,3,1,3,1,16,1,7,11,5,1,1,1,3,1,3,1,16,1,7,1,1,1,5,1,1,1,5,1,1,1,3,1,3,1,16,1,7,1,1,1,5,11,3,1,3,1,16,1,7,1,1,1,7,1,5,1,5,1,3,1,16,11,7,7,5,1,3,1,24,1,21,1,3,1,24,1,21,7,22,1,25,1,1,1,12,11,25,9,44,1,5,1,44,1,5,1,44,1,5,1,34,11,5,1,34,1,15,1,34,1,15,1,34,1,15,1,34,1,15,1,34,1,15,1,34,1,11,5,34,1,11,1,38,1,11,1,38,1,11,1,38,1,11,1,38,1,11,1,38,13,4
text

@example_scaffold = <<-map.strip
..#..........
..#..........
#######...###
#.#...#...#.#
#############
..#...#...#..
..#####...^..
map

class IntcodeProgram
  def interpret!(_debug: false)
    @state ||= :running # leave state alone so we can call recursively
    @ip, @rb = 0, 0

    loop do
      step! until done? || paused?

      debug_vacuum_robot if _debug
      return @outputs if done?

      raise "running through, cannot read" if reading?

      adjust_ip!
      @state = :running
    end
  end

  def debug_vacuum_robot
    raise if @outputs && @outputs.size > 1

    if @outputs.last == "\n".ord && @previous == @outputs.last
      print "\033[H"
      @outputs = []
      @previous = nil
      return
    end

    @previous = @outputs.last if @outputs.last

    if (@outputs.last || 0) > 128
      puts receive_signals.last
    else
      print receive_signals.pack("c*")
    end
  end
end
