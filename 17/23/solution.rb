
Instruction = Struct.new(:op, :target, :source)

class Duet
  attr_reader :queue, :sent

  def initialize(instructions)
    @instructions = instructions
  end

  def self.of(text)
    new(
      text.strip.lines.map{|l| parse(l)}
    )
  end

  def solve
  end

  def dup
    self.class.new(@instructions.dup)
  end

  def duet
    @program0 = dup
      .tap{|this| this.instance_eval{
        @reg = {p: 0}
      }}
    @program1 = dup
      .tap{|this| this.instance_eval{
        @reg = {p: 1}
      }}

    @program0.pair(@program1)
    @program1.pair(@program0)

    until deadlock?
      @program0.interpret
      @program1.interpret
    end

    @program1.sent
  end

  def deadlock?
    @program0.stuck? && @program1.stuck?
  end

  def stuck?
    @partner.queue.empty? && current.op == :rcv
  end

  def pair(other)
    @partner = other
    @pc, @sent, @received, @queue = 0, 0, [], []
  end

  <<-docs
  docs
  def interpret
    case current.op
    when :snd
      @sent += 1
      @queue << value_of(current.target)
    when :rcv
      if @partner.queue.any?
        @reg[current.target.register] = @partner.queue.shift
      else
        # do not increment program counter as we didn't
        # receive anything, wait for partner to execute
        return
      end
    when :jgz
      if value_of(current.target) > 0
        @pc += value_of(current.source)
        return # do not increment program counter again
      end
    when :set
      set(current.target, value_of(current.source))
    when :add
      set(current.target, value_of(current.target) + value_of(current.source))
    when :mul
      set(current.target, value_of(current.target) * value_of(current.source))
    when :mod
      set(current.target, value_of(current.target) % value_of(current.source))
    end

    @pc += 1
  end

  def current
    @instructions[@pc]
  end

  def value_of(val)
    if val.nil?
      pp self
      raise "Nil value"
    end

    if val.respond_to?(:number)
      val.number
    elsif val.respond_to?(:register)
      @reg[val.register] ||= 0
    else
      raise "Unknown value: #{val}"
    end
  end

  def set(reg, val)
    @reg[reg.register] = val
  end

  def self.parse(instruction)
    op, first, second = instruction.split
    target, source = [first, second].map{|v| register_or_value(v)}
    op = op.to_sym
    Instruction.new(op, target, source)
  end

  def self.register_or_value(value)
    return nil if value.nil?

    case value
    when /\d+/
      OpenStruct.new({ number: value.to_i })
    when /\w/
      OpenStruct.new({ register: value.to_sym })
    else
      raise "Unknown value or register: #{value}"
    end
  end
end