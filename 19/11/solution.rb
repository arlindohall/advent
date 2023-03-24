$_debug = false

###########################################################
######################### PAINTER #########################
###########################################################

class Painter
  def initialize(white_squares, location, direction, program)
    @white_squares = white_squares
    @location = location
    @direction = direction
    @program = program
  end

  def dup
    Painter.new(@white_squares.dup, @location.dup, @direction, @program.dup)
  end

  def solve
    [dup.part1, dup.part2]
  end

  def part2
    @visited = Set.new
    @white_squares << @location
    @program.start

    until @program.done?
      @visited << @location
      step
    end

    _debug
    @visited.count
  end

  def part1
    @visited = Set.new
    @program.start

    until @program.done?
      @visited << @location
      step
    end

    @visited.count
  end

  def step
    read_pixel
    2.times { @program.continue }

    take_actions
    @program.continue

    _debug if $_debug

    self
  end

  def read_pixel
    if @white_squares.include?(@location)
      @program.send_signal(1)
    else
      @program.send_signal(0)
    end
  end

  def take_actions
    paint, new_direction = @program.receive_signals
    raise "Machine did not give two outputs" unless paint && new_direction

    paint_pixel(paint)
    turn(new_direction)
    move_forward
  end

  def paint_pixel(value)
    case value
    when 0
      @white_squares.delete(@location)
    when 1
      @white_squares << @location
    else
      raise "Impossible paint value: #{value}"
    end
  end

  def turn(value)
    case value
    when 0
      @direction -= 90
    when 1
      @direction += 90
    else
      raise "Impossible turn value: #{value}"
    end

    @direction %= 360
  end

  def move_forward
    x, y = @location
    case @direction
    when 0
      @location = [x, y - 1] # up
    when 90
      @location = [x + 1, y] # right
    when 180
      @location = [x, y + 1] # down
    when 270
      @location = [x - 1, y] # left
    else
      raise "Impossible direction when stepping: #{@direction}"
    end
  end

  def _debug
    minx, maxx = all_points.map(&:first).minmax
    miny, maxy = all_points.map(&:last).minmax

    minx -= 5
    maxx += 5
    miny -= 5
    maxy += 5

    puts miny
           .upto(maxy)
           .map { |y|
             minx
               .upto(maxx)
               .map do |x|
                 if [x, y] == @location
                   cursor
                 elsif @white_squares.include?([x, y])
                   "#"
                 else
                   "."
                 end
               end
               .join
           }
           .join("\n")
  end

  def cursor
    case @direction
    when 0
      "^"
    when 90
      ">"
    when 180
      "v"
    when 270
      "<"
    end
  end

  def all_points
    @white_squares + Set[@location]
  end

  class << self
    def load(program)
      new(
        Set.new, # sparse representation
        [0, 0],
        0,
        IntcodeProgram.parse(program).dup
      )
    end
  end
end

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

  def prep_channels(inputs = [], outputs = [])
    @inputs = inputs
    @outputs = outputs
    self
  end

  def interpret
    @state ||= :running # leave state alone so we can call recursively
    @ip, @rb = 0, 0

    loop do
      step until done? || paused?

      return @outputs if done?

      raise "running through, cannot read" if reading?

      adjust_ip
      @state = :running
    end
  end

  def start
    @state = :running
    @ip, @rb = 0, 0

    step until done? || paused?

    @outputs if done?
  end

  def continue
    adjust_ip

    @state = :running

    step until done? || paused?

    @outputs if done?
  end

  def adjust_ip
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

  def step
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

@input = <<-text.strip
3,8,1005,8,319,1106,0,11,0,0,0,104,1,104,0,3,8,102,-1,8,10,1001,10,1,10,4,10,108,1,8,10,4,10,101,0,8,28,2,1105,12,10,1006,0,12,3,8,102,-1,8,10,101,1,10,10,4,10,1008,8,0,10,4,10,102,1,8,58,2,107,7,10,1006,0,38,2,1008,3,10,3,8,1002,8,-1,10,1001,10,1,10,4,10,108,0,8,10,4,10,1001,8,0,90,3,8,1002,8,-1,10,101,1,10,10,4,10,108,0,8,10,4,10,101,0,8,112,1006,0,65,1,1103,1,10,1006,0,91,3,8,102,-1,8,10,101,1,10,10,4,10,108,1,8,10,4,10,101,0,8,144,1006,0,32,3,8,1002,8,-1,10,101,1,10,10,4,10,108,1,8,10,4,10,102,1,8,169,1,109,12,10,1006,0,96,1006,0,5,3,8,102,-1,8,10,1001,10,1,10,4,10,108,1,8,10,4,10,101,0,8,201,3,8,102,-1,8,10,1001,10,1,10,4,10,108,0,8,10,4,10,1001,8,0,223,1,4,9,10,2,8,5,10,1,3,4,10,3,8,1002,8,-1,10,1001,10,1,10,4,10,108,1,8,10,4,10,101,0,8,257,1,1,9,10,1006,0,87,3,8,102,-1,8,10,1001,10,1,10,4,10,1008,8,0,10,4,10,102,1,8,287,2,1105,20,10,1,1006,3,10,1,3,4,10,101,1,9,9,1007,9,1002,10,1005,10,15,99,109,641,104,0,104,1,21102,1,932972962600,1,21101,0,336,0,1106,0,440,21101,838483681940,0,1,21101,0,347,0,1106,0,440,3,10,104,0,104,1,3,10,104,0,104,0,3,10,104,0,104,1,3,10,104,0,104,1,3,10,104,0,104,0,3,10,104,0,104,1,21101,3375393987,0,1,21101,394,0,0,1105,1,440,21102,46174071847,1,1,21102,1,405,0,1106,0,440,3,10,104,0,104,0,3,10,104,0,104,0,21101,988648461076,0,1,21101,428,0,0,1106,0,440,21101,0,709580452200,1,21101,439,0,0,1105,1,440,99,109,2,22101,0,-1,1,21101,40,0,2,21102,1,471,3,21102,461,1,0,1106,0,504,109,-2,2106,0,0,0,1,0,0,1,109,2,3,10,204,-1,1001,466,467,482,4,0,1001,466,1,466,108,4,466,10,1006,10,498,1102,0,1,466,109,-2,2105,1,0,0,109,4,1202,-1,1,503,1207,-3,0,10,1006,10,521,21102,1,0,-3,22102,1,-3,1,21201,-2,0,2,21101,0,1,3,21102,540,1,0,1106,0,545,109,-4,2106,0,0,109,5,1207,-3,1,10,1006,10,568,2207,-4,-2,10,1006,10,568,22101,0,-4,-4,1105,1,636,22102,1,-4,1,21201,-3,-1,2,21202,-2,2,3,21102,1,587,0,1105,1,545,22101,0,1,-4,21102,1,1,-1,2207,-4,-2,10,1006,10,606,21101,0,0,-1,22202,-2,-1,-2,2107,0,-3,10,1006,10,628,21201,-1,0,1,21101,0,628,0,106,0,503,21202,-2,-1,-2,22201,-4,-2,-4,109,-5,2106,0,0
text
