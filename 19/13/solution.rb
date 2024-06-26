$_debug = true

###########################################################
######################### INTCODE #########################
###########################################################

class Object
  def plop
    p self
  end
end

class IntcodeProgram
  attr_reader :text

  OPCODES = {
    1 => :add,
    2 => :multiply,
    3 => :read_value,
    4 => :write_value,
    5 => :jump_if_true,
    6 => :jump_if_false,
    7 => :less_than,
    8 => :equals,
    9 => :adjust_relative_base,
    99 => :halt
  }

  SIZE = {
    multiply: 4,
    add: 4,
    read_value: 2,
    write_value: 2,
    jump_if_true: 0,
    jump_if_false: 0,
    less_than: 4,
    equals: 4,
    adjust_relative_base: 2,
    halt: 0
  }

  def initialize(text)
    @text = text
    @inputs = []
    @outputs = []
  end

  def dup
    IntcodeProgram.new(@text.dup)
  end

  def prep_channels!(inputs = [], outputs = [])
    @inputs = inputs
    @outputs = outputs
    self
  end

  def interpret!
    @state ||= :running # leave state alone so we can call recursively
    @ip, @rb = 0, 0

    loop do
      step! until done? || paused?

      return @outputs if done?

      raise "running through, cannot read" if reading?

      adjust_ip!
      @state = :running
    end
  end

  def start!
    @state = :running
    @ip, @rb = 0, 0

    step! until done? || paused?

    @outputs if done?
  end

  def continue!
    adjust_ip!

    @state = :running

    step! until done? || paused?

    @outputs if done?
  end

  def adjust_ip!
    case @state
    when :running
      raise "program was not paused"
    when :writing
      nil # pass because we already incremented the instruction pointer
    when :reading
      @ip -= SIZE[:read_value]
    end
  end

  def done?
    @ip >= @text.length
  end

  def running?
    @state == :running
  end

  def paused?
    reading? || writing?
  end

  def reading?
    @state == :reading
  end

  def writing?
    @state == :writing
  end

  def not_started?
    @state.nil?
  end

  def step!
    perform_opcode
  end

  def perform_opcode
    code = OPCODES[current]
    # _debug(code)

    raise "Unknown opcode #{@ip}, #{current}" unless code
    send(code)
    @ip += SIZE[code]
  end

  def _debug(code)
    [
      "code=>",
      code,
      "ip=>",
      @ip,
      "rb=>",
      @rb,
      "text=>",
      @text[@ip..@ip + SIZE[code] - 1],
      "modes=>",
      modes(SIZE[code] > 2 ? SIZE[code] - 2 : 0),
      "outputs=>",
      @outputs
    ].plop
    @text.plop
    puts
  end

  def halt
    @ip = @text.length
  end

  def multiply
    @text[target(3)] = parameters(2).reduce(&:*)
  end

  def add
    @text[target(3)] = parameters(2).sum
  end

  def read_value
    return pause(:reading) if @inputs.empty?
    @text[target(1)] = @inputs.shift.to_i
  end

  def write_value
    @outputs << parameters(1).first
    pause(:writing)
  end

  def pause(reason = :reading)
    @state = reason
  end

  def jump_if_true
    first, second = parameters(2)
    if first != 0
      @ip = second
    else
      # Increment by size, because we record size as zero above
      @ip += 3
    end
  end

  def jump_if_false
    first, second = parameters(2)
    if first == 0
      @ip = second
    else
      # Increment by size, because we record size as zero above
      @ip += 3
    end
  end

  def less_than
    first, second = parameters(2)
    @text[target(3)] = first < second ? 1 : 0
  end

  def equals
    first, second = parameters(2)
    @text[target(3)] = first == second ? 1 : 0
  end

  def adjust_relative_base
    param = parameters(1).first
    @rb += param
  end

  def parameters(count)
    @text[@ip + 1..@ip + count]
      .zip(modes(count))
      .map { |value, mode| parameter(value, mode) }
  end

  def parameter(value, mode)
    case mode
    when 0
      position(value)
    when 1
      immediate(value)
    when 2
      relative(value)
    end
  end

  def immediate(value)
    value
  end

  def position(value)
    raise "negative reference" if value < 0
    if value > @text.length
      @text.size.upto(value) { @text << 0 }
      @text[value]
    else
      @text[value]
    end
  end

  def relative(value)
    value = @rb + value
    raise "negative reference" if value < 0
    if value > @text.length
      @text.size.upto(value) { @text << 0 }
      @text[value]
    else
      @text[value]
    end
  end

  def target(count)
    case modes(count).last
    when 0
      @text[@ip + count]
    when 1
      raise "cannot write to immediate value"
    when 2
      @rb + @text[@ip + count]
    end
  end

  def modes(count)
    1.upto(count).map { |shift| (@text[@ip] / (10**(shift + 1))) % 10 }
  end

  def current
    @text[@ip] % 100
  end

  def send_signal(val)
    @inputs << val
  end

  def receive_signals
    op = @outputs
    @outputs = []
    op
  end

  class << self
    def parse(text)
      new(text.split(",").map(&:to_i).freeze)
    end
  end
end

##############################################
#################### Game ####################
##############################################

class IntcodeProgram
  attr_reader :state
  def insert_quarter
    @text[0] = 2
  end
end

class Game
  class << self
    def run(program)
      new(IntcodeProgram.parse(program).dup)
    end
  end

  def initialize(program)
    @program = program
  end

  ### PART 2

  def play
    @program.insert_quarter
    @program.start!
    loop do
      calculate_screen
      update_display
      display_screen(skip: !$_debug)
      return if @program.done?
      play_move
    end
  ensure
    puts @score
  end

  PRINT_PROGRESS = false
  def update_display
    return unless PRINT_PROGRESS
    puts @program.state
    calculate_screen
    display_screen
    sleep 0.02
  end

  def calculate_screen
    @program.continue! until @program.reading? || @program.done?
  end

  def display_screen(skip: false)
    @score ||= "invalid: no score"
    @display ||= {}

    @program
      .receive_signals
      .each_slice(3) do |x, y, value|
        if [x, y] == [-1, 0]
          @score = value
        else
          @display[[x, y]] = value
        end
      end

    show_display unless skip
    puts @score unless skip
  end

  def show_display
    minx, maxx = @display.keys.map(&:first).minmax
    miny, maxy = @display.keys.map(&:last).minmax

    print "\033[H"
    miny.upto(maxy) do |y|
      minx.upto(maxx) { |x| show_pixel([x, y]) }
      puts
    end
  end

  def show_pixel(point)
    case @display[point]
    when 0
      print " "
    when 1
      print "#"
    when 2
      print "H"
    when 3
      print "_"
    when 4
      print "o"
    when nil
      print " "
    end
  end

  def play_move
    @program.send_signal(best_move)
    @program.continue!
  end

  def best_move
    ball_location <=> paddle_location
  end

  def paddle_location
    item_location(3)
  end

  def ball_location
    item_location(4)
  end

  def item_location(item)
    @display
      .filter { |_, v| v == item } # {coords => item}
      .first # [coords, item]
      .first # coords
      .first # x
  end

  def input_move
    case $stdin.getch
    when "j"
      @program.send_signal(-1)
    when "l"
      @program.send_signal(1)
    else # including the desired key, 'k'
      @program.send_signal(0)
    end
    @program.continue!
  end

  ### PART 1

  def count_block_tiles
    @program.dup.interpret!.each_slice(3).filter { |slice| slice[2] == 2 }.count
  end
end

def solve
  [Game.run(@input).count_block_tiles, Game.run(@input).play]
end

@input = <<-program.strip
1,380,379,385,1008,2739,308106,381,1005,381,12,99,109,2740,1101,0,0,383,1102,1,0,382,20102,1,382,1,21001,383,0,2,21102,37,1,0,1106,0,578,4,382,4,383,204,1,1001,382,1,382,1007,382,42,381,1005,381,22,1001,383,1,383,1007,383,25,381,1005,381,18,1006,385,69,99,104,-1,104,0,4,386,3,384,1007,384,0,381,1005,381,94,107,0,384,381,1005,381,108,1105,1,161,107,1,392,381,1006,381,161,1101,0,-1,384,1106,0,119,1007,392,40,381,1006,381,161,1101,0,1,384,20102,1,392,1,21102,23,1,2,21102,1,0,3,21102,1,138,0,1105,1,549,1,392,384,392,20102,1,392,1,21101,0,23,2,21102,3,1,3,21101,161,0,0,1106,0,549,1102,1,0,384,20001,388,390,1,20102,1,389,2,21102,180,1,0,1105,1,578,1206,1,213,1208,1,2,381,1006,381,205,20001,388,390,1,20102,1,389,2,21102,205,1,0,1106,0,393,1002,390,-1,390,1102,1,1,384,20102,1,388,1,20001,389,391,2,21101,0,228,0,1106,0,578,1206,1,261,1208,1,2,381,1006,381,253,20101,0,388,1,20001,389,391,2,21102,253,1,0,1106,0,393,1002,391,-1,391,1101,0,1,384,1005,384,161,20001,388,390,1,20001,389,391,2,21102,279,1,0,1105,1,578,1206,1,316,1208,1,2,381,1006,381,304,20001,388,390,1,20001,389,391,2,21101,0,304,0,1106,0,393,1002,390,-1,390,1002,391,-1,391,1102,1,1,384,1005,384,161,21001,388,0,1,20102,1,389,2,21102,1,0,3,21102,338,1,0,1105,1,549,1,388,390,388,1,389,391,389,20101,0,388,1,21002,389,1,2,21102,1,4,3,21102,365,1,0,1106,0,549,1007,389,24,381,1005,381,75,104,-1,104,0,104,0,99,0,1,0,0,0,0,0,0,427,19,20,1,1,21,109,3,21202,-2,1,1,21202,-1,1,2,21102,1,0,3,21101,0,414,0,1105,1,549,21202,-2,1,1,22101,0,-1,2,21101,429,0,0,1106,0,601,2102,1,1,435,1,386,0,386,104,-1,104,0,4,386,1001,387,-1,387,1005,387,451,99,109,-3,2105,1,0,109,8,22202,-7,-6,-3,22201,-3,-5,-3,21202,-4,64,-2,2207,-3,-2,381,1005,381,492,21202,-2,-1,-1,22201,-3,-1,-3,2207,-3,-2,381,1006,381,481,21202,-4,8,-2,2207,-3,-2,381,1005,381,518,21202,-2,-1,-1,22201,-3,-1,-3,2207,-3,-2,381,1006,381,507,2207,-3,-4,381,1005,381,540,21202,-4,-1,-1,22201,-3,-1,-3,2207,-3,-4,381,1006,381,529,22102,1,-3,-7,109,-8,2106,0,0,109,4,1202,-2,42,566,201,-3,566,566,101,639,566,566,2102,1,-1,0,204,-3,204,-2,204,-1,109,-4,2105,1,0,109,3,1202,-1,42,593,201,-2,593,593,101,639,593,593,21002,0,1,-2,109,-3,2106,0,0,109,3,22102,25,-2,1,22201,1,-1,1,21101,541,0,2,21102,532,1,3,21102,1,1050,4,21102,630,1,0,1105,1,456,21201,1,1689,-2,109,-3,2105,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,2,0,0,2,2,0,2,2,0,0,2,0,0,2,2,0,2,2,2,2,0,2,2,2,2,2,2,2,2,2,2,2,2,0,2,2,0,0,1,1,0,0,0,2,2,0,2,2,0,2,2,0,2,2,2,2,2,2,2,0,2,2,2,2,2,2,0,2,2,2,0,0,2,2,2,0,2,2,0,0,1,1,0,2,2,0,0,0,2,0,2,0,2,2,0,2,2,2,2,2,2,2,2,0,0,2,0,0,2,0,2,2,2,2,0,2,0,0,2,0,2,0,1,1,0,2,2,0,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,0,2,2,0,2,0,0,2,2,2,0,0,2,2,0,2,0,0,0,2,0,1,1,0,2,0,2,2,0,2,2,2,2,0,2,0,0,2,2,0,2,0,0,2,2,0,2,0,0,2,2,2,0,2,2,0,2,2,0,2,0,2,0,1,1,0,2,2,2,0,2,2,0,0,2,0,2,0,2,2,2,0,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,0,2,2,2,2,2,2,0,1,1,0,2,2,0,2,2,2,0,2,0,2,2,2,2,0,2,2,2,0,0,0,2,0,2,0,2,2,2,2,2,2,2,0,2,0,2,2,2,2,0,1,1,0,2,0,2,2,2,0,2,2,2,0,0,2,2,0,2,2,2,2,0,2,0,2,2,0,0,2,2,2,2,2,2,2,2,2,0,2,2,2,0,1,1,0,0,0,2,2,2,0,2,2,2,2,2,2,0,2,0,2,2,0,2,0,2,2,2,2,2,2,2,2,2,2,2,0,2,2,0,2,2,2,0,1,1,0,0,2,2,0,2,2,0,0,2,2,2,2,2,0,2,2,2,0,0,2,2,2,0,0,2,0,0,0,2,0,2,0,0,0,0,2,2,2,0,1,1,0,0,2,0,0,2,0,0,2,0,2,2,0,2,2,2,0,0,2,2,2,2,2,2,2,2,2,0,2,0,2,0,0,2,2,0,2,2,0,0,1,1,0,2,0,0,2,2,2,2,2,2,0,2,0,2,0,0,0,0,0,2,2,2,2,2,2,2,0,0,2,0,2,2,0,2,0,2,2,2,0,0,1,1,0,2,2,2,2,0,2,0,2,2,0,2,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,0,2,2,2,2,0,0,0,1,1,0,2,2,2,0,2,0,0,2,2,2,0,2,0,0,0,2,0,2,2,0,2,0,0,0,2,0,2,2,2,2,0,0,0,2,2,0,0,2,0,1,1,0,2,2,0,0,2,0,2,2,0,2,2,2,2,2,0,0,0,0,2,0,0,0,2,2,2,2,0,2,2,2,0,0,0,2,2,0,2,0,0,1,1,0,2,2,2,2,2,2,0,0,0,0,2,2,0,0,2,2,0,0,2,0,2,2,2,2,2,2,0,2,2,2,2,0,2,0,0,2,2,2,0,1,1,0,2,2,2,2,2,2,2,0,0,2,2,2,2,2,0,2,2,0,2,2,2,2,2,2,2,2,2,0,0,0,2,0,2,2,2,2,2,2,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,8,84,79,17,14,11,27,41,35,21,90,10,22,80,41,52,40,45,77,96,57,22,12,11,75,8,2,23,58,93,48,94,66,24,40,73,58,39,42,33,87,85,84,56,58,47,39,14,28,61,95,14,49,90,73,64,84,15,82,2,41,48,32,13,1,51,32,79,45,43,11,66,90,9,10,86,7,51,88,92,89,52,62,22,48,9,18,78,52,10,6,66,65,38,62,30,65,3,13,73,21,98,56,37,93,8,28,92,59,19,50,49,98,45,73,21,63,32,28,12,57,86,87,69,68,95,14,16,24,17,10,45,92,1,10,85,30,16,67,42,91,62,26,36,66,9,36,95,20,48,14,7,16,22,67,93,2,34,30,86,46,48,33,22,95,43,88,1,32,36,15,67,4,50,68,12,44,66,53,77,13,91,48,35,2,62,69,56,36,67,5,68,14,10,8,15,5,62,23,74,27,74,74,22,87,43,85,37,55,69,91,68,82,96,20,30,47,32,74,54,86,68,95,25,80,68,93,64,41,19,86,36,49,60,87,16,34,35,67,30,53,78,17,38,18,94,35,16,39,10,92,82,41,24,21,52,11,12,81,39,40,33,65,59,91,46,21,59,81,11,49,18,81,40,52,57,13,10,5,31,88,79,31,65,15,45,15,48,3,20,52,55,58,26,46,48,52,92,96,3,36,91,60,8,87,5,94,97,55,63,52,36,45,27,46,97,37,91,27,90,29,2,12,54,78,68,3,34,31,47,3,89,59,41,93,97,25,66,24,43,93,45,98,54,6,42,77,73,73,6,72,20,31,48,95,79,27,38,3,9,60,64,55,6,74,88,54,57,64,60,4,62,42,53,50,53,15,26,58,9,28,36,89,85,95,20,97,70,60,95,32,5,29,86,55,61,13,87,78,62,47,42,94,14,86,89,38,42,86,13,37,86,25,59,69,32,58,27,36,71,45,50,66,74,28,38,11,22,56,57,3,88,49,59,9,82,37,18,86,71,72,74,83,70,31,90,34,69,41,3,19,32,9,14,7,91,38,66,90,75,4,22,87,39,38,44,95,81,12,35,2,53,54,61,69,98,21,43,32,79,63,53,10,15,19,28,65,18,24,56,51,54,93,57,82,28,69,16,95,15,15,92,24,65,20,55,22,42,23,46,57,26,45,38,51,21,47,84,74,27,80,23,39,42,60,32,44,81,53,90,15,5,45,16,80,20,74,1,78,84,20,35,48,47,46,38,76,37,46,75,36,34,83,38,7,75,33,12,61,97,10,46,71,13,56,63,11,79,65,75,87,87,87,34,59,30,4,74,80,32,12,57,74,86,85,28,19,60,5,8,26,82,53,24,3,91,49,71,72,53,78,94,63,91,72,79,16,36,44,13,39,15,72,67,30,79,39,76,69,86,85,8,26,58,54,47,82,7,86,78,64,24,95,73,6,93,45,33,2,6,75,68,63,55,37,87,24,47,22,93,68,34,85,42,55,77,22,15,94,62,56,53,15,37,25,16,33,81,26,76,77,20,84,89,85,25,31,25,25,35,53,6,89,93,82,2,86,38,36,75,12,30,76,37,5,44,78,65,11,49,80,49,34,67,72,25,87,97,46,69,42,7,43,58,82,58,53,89,54,34,80,38,31,21,37,66,43,90,72,29,75,17,19,83,58,94,80,46,19,50,60,25,74,91,21,48,18,53,91,37,17,35,16,23,85,89,15,84,61,78,93,19,67,96,23,59,64,9,56,45,74,54,52,69,84,91,61,45,2,39,30,62,26,83,61,9,32,40,91,31,40,54,70,53,92,74,3,66,27,46,5,82,92,59,48,23,75,23,40,95,4,29,9,91,57,19,80,42,47,75,72,30,35,15,38,44,64,46,16,11,51,14,29,84,4,1,40,62,93,42,24,66,53,12,95,50,32,31,40,45,11,97,62,3,20,21,84,95,75,85,50,61,44,24,80,26,6,74,62,64,16,29,95,38,27,32,1,2,55,27,23,46,59,16,57,5,64,55,92,91,11,4,38,22,31,66,86,73,26,35,81,92,18,27,39,40,39,69,98,11,78,98,43,22,72,70,15,35,87,68,49,33,88,28,50,56,31,64,75,66,59,32,64,18,49,78,13,76,86,1,6,58,45,90,55,64,46,66,40,98,87,23,20,46,70,98,37,3,91,7,10,61,65,79,9,2,6,56,25,80,11,21,90,13,9,74,57,91,28,18,79,78,38,34,56,13,85,58,61,3,80,42,59,94,91,8,48,49,11,52,77,63,28,29,97,76,40,53,19,81,92,6,74,63,33,35,95,41,33,81,78,47,68,45,43,9,31,55,80,43,5,2,7,7,6,78,35,9,13,29,80,80,53,64,98,81,18,58,88,38,308106
program
