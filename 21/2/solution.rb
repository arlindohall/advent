def solve
  [
    Submarine.new(read_input).final_depth_by_height,
    AimingSub.new(read_input).final_depth_by_height
  ]
end

class Submarine
  attr_reader :text, :x, :y
  def initialize(text)
    @text = text
    @x = 0
    @y = 0
  end

  def final_depth_by_height
    follow_instructions.then { x * y }
  end

  def follow_instructions
    instructions.each { |inst| follow(inst) }
  end

  def instructions
    text.split("\n")
  end

  def follow(instruction)
    case instruction
    when /up/
      @y -= instruction.split.second.to_i
    when /down/
      @y += instruction.split.second.to_i
    when /forward/
      @x += instruction.split.second.to_i
    end
  end
end

class AimingSub < Submarine
  attr_reader :aim

  def initialize(text)
    super(text)
  end

  def follow(instruction)
    @aim ||= 0
    case instruction
    when /up/
      @aim -= instruction.split.second.to_i
    when /down/
      @aim += instruction.split.second.to_i
    when /forward/
      @x += instruction.split.second.to_i
      @y += aim * instruction.split.second.to_i
    end
  end
end
