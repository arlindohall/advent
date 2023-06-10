$_debug = false

def solve =
  read_input.then do |it|
    puts ClockCircuit.parse(it).execute!
    puts ClockCircuit.parse(it).draw!
  end

class ClockCircuit
  shape :instructions

  attr_reader :clock, :duration, :action, :tracked, :drawn

  def execute!
    init!
    cycle until done?

    tracked.map(&:product).sum
  end

  def draw!
    init!
    cycle until done?

    puts drawn.each_slice(40).map { |row| row.join }.join("\n")
  end

  def cycle
    @clock += 1
    begin_execution
    _debug(action:, regs:, clock:, duration:)
    record_x
    record_drawn
    end_execution
  end

  def begin_execution
    return unless duration == 0
    @action = instructions.shift
    @duration =
      case action.first
      when "addx"
        2
      when "noop"
        1
      end
  end

  def record_x
    return unless (clock - 20) % 40 == 0
    tracked << [clock, regs[:x]]
  end

  def record_drawn
    drawn << sprite.darken_squares
  end

  def sprite
    sprite_window.include?(regs[:x]) ? "#" : "."
  end

  def sprite_window
    center = (clock - 1) % 40
    center - 1..center + 1
  end

  def end_execution
    @duration -= 1
    return unless duration == 0
    apply
  end

  def apply
    inst, *args = action
    case inst
    when "addx"
      regs[:x] += args.first.to_i
    when "noop"
    end
  end

  def init!
    @clock = 0
    @duration = 0
    @action = ""
    @tracked = []
    @drawn = []
  end

  def done?
    duration == 0 && instructions.empty?
  end

  def regs
    @regs ||= Hash.new { |h, k| h[k] = 1 }
  end

  def self.parse(text)
    new(instructions: text.split("\n").map(&:split))
  end
end
