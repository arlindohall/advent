
class Instruction < Struct.new(:repr)
  def op
    @op ||= repr.split(" ").first.to_sym
  end

  def args
    @arg ||= repr.split(" ").drop(1).map(&:to_i)
  end

  def execution_count
    @execution_count ||= 0
    @execution_count += 1
  end

  def act(state)
    send(op, args, state)
  end

  def nop(args, state)
    state.transform
  end

  def acc(args, state)
    state.transform(acc: state.acc + args.first)
  end

  def jmp(args, state)
    state.transform(ip: state.ip + args.first)
  end
end

class State < Struct.new(:acc, :ip)
  def initialize(**kwargs)
    self.acc = kwargs[:acc] || 0
    self.ip = kwargs[:ip] || 0
  end

  def dup
    State.new(acc:, ip:)
  end

  def transform(acc: nil, ip: nil)
    State.new(
      acc: acc ? acc : self.acc,
      ip: ip ? ip : self.ip + 1,
    )
  end
end

class Console < Struct.new(:text)
  ## specific to today
  def exec_until_infinite_loop
    self.state ||= State.new
    until current.execution_count > 1
      # puts self.state
      execute_instruction
    end

    return state.acc
  end

  def halts_if_swapped(idx)
    # puts "Checking for halt by swapping inst/#{idx}"
    case program[idx].op
    when :acc
      return false
    when :nop
      program[idx] = Instruction.new("jmp #{program[idx].args.join(" ")}")
    when :jmp
      program[idx] = Instruction.new("nop #{program[idx].args.join(" ")}")
    end

    execution_count = 0
    until execution_count > 1000 # more than instruction count
      return true if state.ip >= program.size || state.ip < 0
      return false if current.execution_count > 1
      execute_instruction
      execution_count += 1
    end

    false
  end

  def find_corrupted_instruction
    program.each_index do |idx|
      dup.tap do |console|
        return console.state.acc if console.halts_if_swapped(idx)
      end
    end

    raise "No corrupted instruction found"
  end
  ## specific to today

  attr_accessor :state

  def dup
    other = Console.new(text)
    other.state = state ? state.dup : State.new
    other
  end

  def program
    @program ||= text.strip.split("\n").map { Instruction.new(_1) }
  end

  def current
    program[state.ip]
  end

  def execute_instruction
    self.state = current.act(state)
  end
end

def solve
  [
    Console.new(read_example).exec_until_infinite_loop,
    Console.new(read_input).find_corrupted_instruction,
  ]
end