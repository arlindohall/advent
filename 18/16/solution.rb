
INSTRUCTIONS = [
  :addr, :addi, :mulr, :muli, :banr, :bani, :borr, :bori,
  :setr, :seti, :gtir, :gtri, :gtrr, :eqir, :eqri, :eqrr
]

Instruction = Struct.new(:number, :a, :b, :c)

class Watch
  attr_reader :registers
  def initialize(registers)
    @registers = registers
  end

  def instructions_matching(instruction, result)
    INSTRUCTIONS.filter { |name| apply(name, instruction).registers == result }
  end

  def apply(name, instruction)
    value = case name
    when :addr
      register(instruction.a) + register(instruction.b)
    when :addi
      register(instruction.a) + instruction.b
    when :mulr
      register(instruction.a) * register(instruction.b)
    when :muli
      register(instruction.a) * instruction.b
    when :banr
      register(instruction.a) & register(instruction.b)
    when :bani
      register(instruction.a) & instruction.b
    when :borr
      register(instruction.a) | register(instruction.b)
    when :bori
      register(instruction.a) | instruction.b
    when :setr
      register(instruction.a)
    when :seti
      instruction.a
    when :gtir
      instruction.a > register(instruction.b) ? 1 : 0
    when :gtri
      register(instruction.a) > instruction.b ? 1 : 0
    when :gtrr
      register(instruction.a) > register(instruction.b) ? 1 : 0
    when :eqir
      instruction.a == register(instruction.b) ? 1 : 0
    when :eqri
      register(instruction.a) == instruction.b ? 1 : 0
    when :eqrr
      register(instruction.a) == register(instruction.b) ? 1 : 0
    else
      raise "Unknown instruction name #{name}"
    end
    regs = @registers.dup
    regs[instruction.c] = value
    Watch.new(regs)
  end

  def register(i)
    @registers[i]
  end
end

class Observation
  def initialize(before, instruction, after)
    @before = before
    @instruction = instruction
    @after = after
  end

  def instructions_matching
    @before.instructions_matching(@instruction, @after)
  end

  def number
    @instruction.number
  end
end

class ObservationList
  attr_reader :samples
  def initialize(samples)
    @samples = samples
  end

  def self.parse(text)
    new(
      text.split("\n\n")
        .map { |sample| 
          before = /Before:\s+\[(\d+), (\d+), (\d+), (\d+)\]/.match(sample).captures.map(&:to_i)
          instruction = /(\d+) (\d+) (\d+) (\d+)/.match(sample).captures.map(&:to_i)
          after = /After:\s+\[(\d+), (\d+), (\d+), (\d+)\]/.match(sample).captures.map(&:to_i)

          Observation.new(
            Watch.new(before),
            Instruction.new(*instruction),
            after
          )
        }
    )
  end

  def part1
    count_instructions.count { |matches| matches >= 3 }
  end

  def count_instructions
    possible_instructions.map(&:size)
  end

  def possible_instructions
    @samples.map { |obs| obs.instructions_matching }
  end

  def part2(instructions)
    @registers = 4.times.map { 0 }
    instructions
      .split("\n")
      .reject(&:empty?)
      .map { |line| /(\d+) (\d+) (\d+) (\d+)/.match(line).captures.map(&:to_i) }
      .each { |number, a, b, c|
      inst = Instruction.new(number, a, b, c)
      name = instruction_mapping[inst.number]
      raise "Unknown instruction number #{inst.number}" unless name

      @registers = Watch.new(@registers).apply(name, inst).registers
    }

    @registers.first
  end

  def instruction_mapping
    @instruction_mapping ||= _instruction_mapping
  end

  def _instruction_mapping
    pim = possible_instruction_mappings
    mapping = {}
    until pim.values.all? { |set| set.empty? }
      set_decided_keys(pim, mapping)
      remove_decided_keys(pim)
    end
    mapping
  end

  def set_decided_keys(pim, mapping)
    pim.each { |k, v|
      mapping[k] = v.first if v.size == 1
    }
  end

  def remove_decided_keys(mapping)
    decided = mapping.values.filter { |v| v.size == 1 }.reduce(&:+)&.to_set || []
    mapping.each { |k,v|
      mapping[k] = v - decided
    }
  end

  def possible_instruction_mappings
    @samples.group_by(&:number)
      .map { |number, obs| [number, unique_in(obs)] }
      .to_h
  end

  def unique_in(observations)
    observations.map(&:instructions_matching)
      .map(&:to_set)
      .reduce(&:&)
  end
end

@example = <<-observations
Before: [3, 2, 1, 1]
9 2 1 2
After:  [3, 2, 2, 1]
observations

@input = <<-observations
Before: [3, 3, 2, 3]
3 1 2 2
After:  [3, 3, 2, 3]

Before: [1, 3, 0, 1]
12 0 2 3
After:  [1, 3, 0, 0]

Before: [0, 3, 2, 0]
14 2 3 0
After:  [1, 3, 2, 0]

Before: [2, 3, 3, 3]
10 0 3 0
After:  [2, 3, 3, 3]

Before: [0, 1, 2, 0]
7 1 2 3
After:  [0, 1, 2, 0]

Before: [3, 1, 2, 0]
7 1 2 2
After:  [3, 1, 0, 0]

Before: [1, 2, 1, 3]
6 2 2 2
After:  [1, 2, 2, 3]

Before: [1, 3, 2, 3]
3 3 2 3
After:  [1, 3, 2, 2]

Before: [0, 1, 2, 0]
8 0 0 1
After:  [0, 0, 2, 0]

Before: [1, 2, 3, 1]
0 2 3 2
After:  [1, 2, 1, 1]

Before: [3, 2, 2, 1]
9 3 2 3
After:  [3, 2, 2, 1]

Before: [1, 2, 2, 3]
4 0 2 0
After:  [0, 2, 2, 3]

Before: [1, 3, 2, 0]
3 1 2 1
After:  [1, 2, 2, 0]

Before: [3, 0, 0, 3]
1 1 0 1
After:  [3, 0, 0, 3]

Before: [1, 1, 2, 0]
4 0 2 2
After:  [1, 1, 0, 0]

Before: [2, 0, 1, 3]
1 1 0 2
After:  [2, 0, 0, 3]

Before: [3, 2, 2, 1]
9 3 2 2
After:  [3, 2, 1, 1]

Before: [2, 2, 2, 3]
3 3 2 3
After:  [2, 2, 2, 2]

Before: [0, 3, 2, 2]
5 3 1 2
After:  [0, 3, 0, 2]

Before: [2, 0, 2, 1]
9 3 2 3
After:  [2, 0, 2, 1]

Before: [0, 3, 2, 2]
5 3 1 0
After:  [0, 3, 2, 2]

Before: [3, 0, 0, 2]
1 1 0 3
After:  [3, 0, 0, 0]

Before: [1, 3, 2, 2]
11 2 1 1
After:  [1, 0, 2, 2]

Before: [1, 3, 2, 2]
11 2 1 2
After:  [1, 3, 0, 2]

Before: [0, 0, 3, 1]
0 2 3 1
After:  [0, 1, 3, 1]

Before: [2, 2, 2, 1]
9 3 2 1
After:  [2, 1, 2, 1]

Before: [0, 0, 2, 1]
2 2 2 1
After:  [0, 4, 2, 1]

Before: [0, 0, 2, 1]
2 2 2 0
After:  [4, 0, 2, 1]

Before: [2, 3, 0, 2]
15 1 0 2
After:  [2, 3, 2, 2]

Before: [1, 0, 1, 2]
6 2 2 2
After:  [1, 0, 2, 2]

Before: [2, 3, 2, 0]
2 2 2 0
After:  [4, 3, 2, 0]

Before: [1, 3, 3, 2]
5 3 1 3
After:  [1, 3, 3, 0]

Before: [1, 3, 0, 1]
12 0 2 2
After:  [1, 3, 0, 1]

Before: [3, 3, 1, 2]
15 1 3 3
After:  [3, 3, 1, 2]

Before: [0, 1, 1, 0]
13 0 2 1
After:  [0, 0, 1, 0]

Before: [0, 3, 2, 1]
14 2 3 1
After:  [0, 1, 2, 1]

Before: [3, 1, 2, 2]
7 1 2 2
After:  [3, 1, 0, 2]

Before: [2, 1, 2, 3]
2 2 2 1
After:  [2, 4, 2, 3]

Before: [0, 0, 3, 0]
13 0 2 2
After:  [0, 0, 0, 0]

Before: [0, 0, 3, 2]
8 0 0 1
After:  [0, 0, 3, 2]

Before: [2, 2, 2, 2]
2 3 2 3
After:  [2, 2, 2, 4]

Before: [3, 3, 1, 3]
10 2 3 2
After:  [3, 3, 1, 3]

Before: [1, 0, 3, 1]
0 2 3 0
After:  [1, 0, 3, 1]

Before: [3, 0, 1, 2]
15 0 3 1
After:  [3, 2, 1, 2]

Before: [0, 2, 1, 1]
6 2 2 1
After:  [0, 2, 1, 1]

Before: [0, 0, 2, 1]
9 3 2 2
After:  [0, 0, 1, 1]

Before: [0, 2, 1, 2]
13 0 3 0
After:  [0, 2, 1, 2]

Before: [1, 0, 2, 3]
3 3 2 3
After:  [1, 0, 2, 2]

Before: [1, 3, 2, 1]
14 2 3 2
After:  [1, 3, 1, 1]

Before: [0, 0, 2, 1]
9 3 2 0
After:  [1, 0, 2, 1]

Before: [0, 3, 2, 0]
8 0 0 0
After:  [0, 3, 2, 0]

Before: [2, 2, 2, 0]
14 2 3 3
After:  [2, 2, 2, 1]

Before: [3, 3, 2, 3]
11 2 1 2
After:  [3, 3, 0, 3]

Before: [1, 3, 1, 2]
5 3 1 0
After:  [0, 3, 1, 2]

Before: [0, 1, 2, 0]
13 0 1 3
After:  [0, 1, 2, 0]

Before: [1, 3, 1, 2]
5 3 1 3
After:  [1, 3, 1, 0]

Before: [1, 0, 2, 3]
2 2 2 0
After:  [4, 0, 2, 3]

Before: [0, 3, 2, 1]
14 2 3 3
After:  [0, 3, 2, 1]

Before: [0, 3, 2, 0]
11 2 1 2
After:  [0, 3, 0, 0]

Before: [1, 3, 2, 3]
3 1 2 1
After:  [1, 2, 2, 3]

Before: [3, 1, 2, 0]
7 1 2 1
After:  [3, 0, 2, 0]

Before: [0, 1, 0, 3]
13 0 3 0
After:  [0, 1, 0, 3]

Before: [0, 3, 2, 1]
11 2 1 3
After:  [0, 3, 2, 0]

Before: [0, 2, 2, 1]
9 3 2 0
After:  [1, 2, 2, 1]

Before: [3, 1, 2, 1]
9 3 2 1
After:  [3, 1, 2, 1]

Before: [3, 2, 0, 2]
1 2 0 3
After:  [3, 2, 0, 0]

Before: [3, 3, 3, 2]
5 3 1 2
After:  [3, 3, 0, 2]

Before: [3, 0, 1, 3]
1 1 0 2
After:  [3, 0, 0, 3]

Before: [1, 1, 2, 2]
7 1 2 0
After:  [0, 1, 2, 2]

Before: [3, 1, 2, 2]
7 1 2 1
After:  [3, 0, 2, 2]

Before: [3, 1, 0, 1]
1 2 0 3
After:  [3, 1, 0, 0]

Before: [1, 2, 2, 2]
4 0 2 3
After:  [1, 2, 2, 0]

Before: [1, 2, 0, 0]
12 0 2 1
After:  [1, 0, 0, 0]

Before: [0, 2, 2, 1]
2 1 2 3
After:  [0, 2, 2, 4]

Before: [0, 0, 3, 1]
13 0 3 1
After:  [0, 0, 3, 1]

Before: [0, 0, 2, 1]
14 2 3 3
After:  [0, 0, 2, 1]

Before: [2, 3, 2, 1]
11 2 1 1
After:  [2, 0, 2, 1]

Before: [2, 0, 1, 1]
1 1 0 2
After:  [2, 0, 0, 1]

Before: [2, 3, 1, 2]
6 2 2 0
After:  [2, 3, 1, 2]

Before: [2, 3, 2, 2]
11 2 1 0
After:  [0, 3, 2, 2]

Before: [3, 2, 2, 0]
2 1 2 2
After:  [3, 2, 4, 0]

Before: [0, 3, 1, 3]
13 0 1 2
After:  [0, 3, 0, 3]

Before: [0, 3, 2, 1]
11 2 1 1
After:  [0, 0, 2, 1]

Before: [2, 3, 2, 2]
5 3 1 2
After:  [2, 3, 0, 2]

Before: [2, 3, 2, 1]
15 1 0 1
After:  [2, 2, 2, 1]

Before: [2, 3, 2, 3]
11 2 1 2
After:  [2, 3, 0, 3]

Before: [0, 1, 2, 3]
7 1 2 1
After:  [0, 0, 2, 3]

Before: [0, 1, 3, 2]
13 0 2 2
After:  [0, 1, 0, 2]

Before: [3, 3, 2, 2]
3 0 2 3
After:  [3, 3, 2, 2]

Before: [2, 0, 2, 1]
9 3 2 2
After:  [2, 0, 1, 1]

Before: [0, 0, 2, 0]
14 2 3 0
After:  [1, 0, 2, 0]

Before: [3, 1, 2, 1]
7 1 2 1
After:  [3, 0, 2, 1]

Before: [0, 2, 2, 1]
14 2 3 1
After:  [0, 1, 2, 1]

Before: [1, 2, 2, 3]
10 1 3 3
After:  [1, 2, 2, 2]

Before: [3, 1, 2, 3]
3 3 2 0
After:  [2, 1, 2, 3]

Before: [0, 2, 2, 2]
8 0 0 2
After:  [0, 2, 0, 2]

Before: [0, 2, 2, 3]
8 0 0 3
After:  [0, 2, 2, 0]

Before: [0, 1, 0, 2]
8 0 0 2
After:  [0, 1, 0, 2]

Before: [1, 3, 2, 1]
9 3 2 3
After:  [1, 3, 2, 1]

Before: [3, 0, 2, 1]
14 2 3 2
After:  [3, 0, 1, 1]

Before: [1, 0, 2, 1]
2 2 2 2
After:  [1, 0, 4, 1]

Before: [0, 3, 0, 2]
5 3 1 0
After:  [0, 3, 0, 2]

Before: [3, 1, 2, 3]
7 1 2 1
After:  [3, 0, 2, 3]

Before: [2, 3, 2, 2]
11 2 1 1
After:  [2, 0, 2, 2]

Before: [3, 0, 2, 2]
3 0 2 0
After:  [2, 0, 2, 2]

Before: [1, 2, 2, 0]
4 0 2 0
After:  [0, 2, 2, 0]

Before: [1, 3, 0, 2]
5 3 1 0
After:  [0, 3, 0, 2]

Before: [1, 1, 2, 2]
7 1 2 2
After:  [1, 1, 0, 2]

Before: [0, 2, 0, 0]
8 0 0 1
After:  [0, 0, 0, 0]

Before: [3, 3, 2, 1]
11 2 1 0
After:  [0, 3, 2, 1]

Before: [3, 3, 1, 2]
5 3 1 0
After:  [0, 3, 1, 2]

Before: [3, 2, 3, 3]
15 0 1 0
After:  [2, 2, 3, 3]

Before: [1, 1, 2, 3]
3 3 2 0
After:  [2, 1, 2, 3]

Before: [2, 0, 2, 1]
1 1 0 1
After:  [2, 0, 2, 1]

Before: [1, 0, 0, 1]
12 0 2 3
After:  [1, 0, 0, 0]

Before: [3, 2, 2, 0]
3 0 2 0
After:  [2, 2, 2, 0]

Before: [1, 1, 0, 0]
12 0 2 2
After:  [1, 1, 0, 0]

Before: [1, 3, 3, 2]
5 3 1 1
After:  [1, 0, 3, 2]

Before: [2, 1, 2, 1]
9 3 2 1
After:  [2, 1, 2, 1]

Before: [2, 0, 2, 3]
15 3 0 2
After:  [2, 0, 2, 3]

Before: [2, 0, 2, 1]
9 3 2 1
After:  [2, 1, 2, 1]

Before: [3, 3, 2, 0]
2 2 2 1
After:  [3, 4, 2, 0]

Before: [3, 2, 2, 2]
15 0 3 3
After:  [3, 2, 2, 2]

Before: [0, 2, 3, 1]
13 0 3 3
After:  [0, 2, 3, 0]

Before: [1, 1, 2, 0]
4 0 2 0
After:  [0, 1, 2, 0]

Before: [2, 2, 2, 0]
0 2 1 3
After:  [2, 2, 2, 0]

Before: [0, 3, 2, 2]
11 2 1 2
After:  [0, 3, 0, 2]

Before: [1, 3, 2, 1]
4 0 2 3
After:  [1, 3, 2, 0]

Before: [3, 0, 2, 0]
1 1 0 1
After:  [3, 0, 2, 0]

Before: [3, 1, 1, 2]
15 0 3 1
After:  [3, 2, 1, 2]

Before: [1, 0, 2, 1]
4 0 2 1
After:  [1, 0, 2, 1]

Before: [2, 0, 1, 0]
6 2 2 1
After:  [2, 2, 1, 0]

Before: [3, 1, 2, 3]
3 0 2 3
After:  [3, 1, 2, 2]

Before: [3, 0, 3, 1]
0 2 3 3
After:  [3, 0, 3, 1]

Before: [0, 2, 2, 1]
2 1 2 1
After:  [0, 4, 2, 1]

Before: [1, 3, 1, 2]
6 2 2 2
After:  [1, 3, 2, 2]

Before: [3, 1, 2, 0]
14 2 3 2
After:  [3, 1, 1, 0]

Before: [1, 0, 2, 2]
4 0 2 1
After:  [1, 0, 2, 2]

Before: [3, 3, 2, 1]
9 3 2 2
After:  [3, 3, 1, 1]

Before: [1, 3, 2, 2]
5 3 1 1
After:  [1, 0, 2, 2]

Before: [1, 2, 2, 1]
4 0 2 0
After:  [0, 2, 2, 1]

Before: [0, 2, 2, 2]
0 2 1 0
After:  [0, 2, 2, 2]

Before: [0, 0, 3, 3]
8 0 0 0
After:  [0, 0, 3, 3]

Before: [1, 2, 1, 2]
6 2 2 3
After:  [1, 2, 1, 2]

Before: [1, 2, 0, 0]
12 0 2 0
After:  [0, 2, 0, 0]

Before: [2, 3, 2, 1]
11 2 1 0
After:  [0, 3, 2, 1]

Before: [3, 2, 2, 3]
15 3 1 2
After:  [3, 2, 2, 3]

Before: [3, 1, 0, 2]
1 2 0 0
After:  [0, 1, 0, 2]

Before: [0, 2, 1, 0]
8 0 0 2
After:  [0, 2, 0, 0]

Before: [1, 2, 2, 2]
2 2 2 1
After:  [1, 4, 2, 2]

Before: [2, 1, 2, 3]
15 3 0 1
After:  [2, 2, 2, 3]

Before: [2, 0, 2, 3]
1 1 0 3
After:  [2, 0, 2, 0]

Before: [0, 2, 2, 0]
0 2 1 0
After:  [0, 2, 2, 0]

Before: [1, 2, 2, 1]
14 2 3 1
After:  [1, 1, 2, 1]

Before: [1, 1, 2, 3]
7 1 2 2
After:  [1, 1, 0, 3]

Before: [0, 1, 1, 0]
6 2 2 0
After:  [2, 1, 1, 0]

Before: [3, 3, 0, 2]
5 3 1 3
After:  [3, 3, 0, 0]

Before: [3, 3, 1, 3]
6 2 2 3
After:  [3, 3, 1, 2]

Before: [2, 3, 2, 0]
3 1 2 0
After:  [2, 3, 2, 0]

Before: [0, 3, 3, 1]
8 0 0 0
After:  [0, 3, 3, 1]

Before: [0, 2, 1, 1]
6 2 2 2
After:  [0, 2, 2, 1]

Before: [0, 3, 2, 3]
3 3 2 0
After:  [2, 3, 2, 3]

Before: [2, 1, 2, 0]
7 1 2 0
After:  [0, 1, 2, 0]

Before: [1, 1, 2, 2]
4 0 2 0
After:  [0, 1, 2, 2]

Before: [1, 3, 3, 1]
0 2 3 3
After:  [1, 3, 3, 1]

Before: [3, 1, 3, 1]
0 2 3 1
After:  [3, 1, 3, 1]

Before: [1, 1, 0, 2]
12 0 2 1
After:  [1, 0, 0, 2]

Before: [0, 3, 3, 3]
8 0 0 3
After:  [0, 3, 3, 0]

Before: [2, 0, 3, 0]
1 1 0 3
After:  [2, 0, 3, 0]

Before: [2, 1, 2, 1]
14 2 3 0
After:  [1, 1, 2, 1]

Before: [2, 1, 2, 0]
7 1 2 1
After:  [2, 0, 2, 0]

Before: [2, 3, 3, 3]
10 0 3 1
After:  [2, 2, 3, 3]

Before: [3, 2, 0, 3]
15 0 1 0
After:  [2, 2, 0, 3]

Before: [2, 2, 2, 0]
0 2 1 0
After:  [0, 2, 2, 0]

Before: [2, 0, 1, 3]
1 1 0 3
After:  [2, 0, 1, 0]

Before: [3, 1, 0, 2]
1 2 0 1
After:  [3, 0, 0, 2]

Before: [3, 0, 2, 1]
9 3 2 1
After:  [3, 1, 2, 1]

Before: [3, 3, 2, 0]
3 0 2 3
After:  [3, 3, 2, 2]

Before: [2, 0, 2, 1]
2 2 2 0
After:  [4, 0, 2, 1]

Before: [0, 1, 0, 1]
8 0 0 2
After:  [0, 1, 0, 1]

Before: [3, 0, 2, 0]
2 2 2 1
After:  [3, 4, 2, 0]

Before: [1, 3, 2, 2]
11 2 1 0
After:  [0, 3, 2, 2]

Before: [1, 0, 0, 0]
12 0 2 2
After:  [1, 0, 0, 0]

Before: [3, 1, 2, 2]
2 3 2 2
After:  [3, 1, 4, 2]

Before: [0, 0, 2, 2]
2 3 2 3
After:  [0, 0, 2, 4]

Before: [2, 3, 2, 3]
3 1 2 3
After:  [2, 3, 2, 2]

Before: [2, 3, 1, 3]
10 2 3 3
After:  [2, 3, 1, 1]

Before: [3, 2, 2, 3]
3 3 2 0
After:  [2, 2, 2, 3]

Before: [2, 0, 1, 0]
6 2 2 2
After:  [2, 0, 2, 0]

Before: [1, 2, 2, 0]
4 0 2 3
After:  [1, 2, 2, 0]

Before: [3, 3, 1, 2]
5 3 1 3
After:  [3, 3, 1, 0]

Before: [3, 2, 2, 1]
9 3 2 1
After:  [3, 1, 2, 1]

Before: [2, 0, 1, 3]
6 2 2 1
After:  [2, 2, 1, 3]

Before: [0, 1, 3, 2]
8 0 0 3
After:  [0, 1, 3, 0]

Before: [1, 3, 0, 2]
12 0 2 0
After:  [0, 3, 0, 2]

Before: [3, 0, 3, 1]
0 2 3 1
After:  [3, 1, 3, 1]

Before: [0, 3, 3, 2]
5 3 1 3
After:  [0, 3, 3, 0]

Before: [0, 0, 3, 2]
8 0 0 2
After:  [0, 0, 0, 2]

Before: [3, 2, 2, 3]
0 2 1 0
After:  [0, 2, 2, 3]

Before: [2, 3, 2, 0]
2 0 2 1
After:  [2, 4, 2, 0]

Before: [0, 1, 1, 2]
8 0 0 1
After:  [0, 0, 1, 2]

Before: [3, 0, 2, 1]
3 0 2 2
After:  [3, 0, 2, 1]

Before: [3, 2, 2, 3]
15 3 1 1
After:  [3, 2, 2, 3]

Before: [1, 2, 2, 0]
0 2 1 3
After:  [1, 2, 2, 0]

Before: [3, 2, 1, 1]
6 2 2 3
After:  [3, 2, 1, 2]

Before: [0, 0, 2, 1]
13 0 2 0
After:  [0, 0, 2, 1]

Before: [0, 0, 1, 1]
6 2 2 0
After:  [2, 0, 1, 1]

Before: [0, 1, 3, 3]
13 0 2 2
After:  [0, 1, 0, 3]

Before: [2, 2, 0, 3]
10 1 3 0
After:  [2, 2, 0, 3]

Before: [2, 2, 2, 3]
2 1 2 1
After:  [2, 4, 2, 3]

Before: [2, 2, 2, 0]
14 2 3 0
After:  [1, 2, 2, 0]

Before: [0, 3, 3, 1]
8 0 0 3
After:  [0, 3, 3, 0]

Before: [2, 2, 2, 1]
9 3 2 3
After:  [2, 2, 2, 1]

Before: [1, 3, 1, 2]
6 2 2 3
After:  [1, 3, 1, 2]

Before: [1, 1, 1, 1]
6 2 2 3
After:  [1, 1, 1, 2]

Before: [0, 2, 2, 1]
2 2 2 3
After:  [0, 2, 2, 4]

Before: [1, 3, 2, 2]
4 0 2 0
After:  [0, 3, 2, 2]

Before: [1, 3, 1, 3]
6 2 2 3
After:  [1, 3, 1, 2]

Before: [0, 1, 1, 2]
13 0 2 1
After:  [0, 0, 1, 2]

Before: [3, 2, 2, 3]
3 0 2 1
After:  [3, 2, 2, 3]

Before: [1, 3, 3, 3]
10 0 3 3
After:  [1, 3, 3, 1]

Before: [0, 0, 1, 0]
6 2 2 1
After:  [0, 2, 1, 0]

Before: [0, 3, 3, 1]
8 0 0 2
After:  [0, 3, 0, 1]

Before: [2, 1, 0, 3]
15 3 0 1
After:  [2, 2, 0, 3]

Before: [1, 0, 0, 3]
12 0 2 0
After:  [0, 0, 0, 3]

Before: [1, 0, 0, 3]
12 0 2 2
After:  [1, 0, 0, 3]

Before: [2, 3, 2, 2]
5 3 1 1
After:  [2, 0, 2, 2]

Before: [1, 0, 0, 2]
12 0 2 0
After:  [0, 0, 0, 2]

Before: [0, 2, 1, 1]
6 2 2 0
After:  [2, 2, 1, 1]

Before: [0, 0, 1, 2]
8 0 0 2
After:  [0, 0, 0, 2]

Before: [0, 3, 2, 3]
13 0 1 2
After:  [0, 3, 0, 3]

Before: [3, 1, 2, 1]
9 3 2 0
After:  [1, 1, 2, 1]

Before: [1, 3, 2, 3]
4 0 2 1
After:  [1, 0, 2, 3]

Before: [1, 0, 0, 2]
12 0 2 3
After:  [1, 0, 0, 0]

Before: [2, 2, 0, 3]
15 3 1 2
After:  [2, 2, 2, 3]

Before: [0, 0, 3, 2]
13 0 3 1
After:  [0, 0, 3, 2]

Before: [1, 0, 2, 2]
4 0 2 2
After:  [1, 0, 0, 2]

Before: [1, 2, 1, 1]
6 2 2 3
After:  [1, 2, 1, 2]

Before: [1, 1, 2, 1]
4 0 2 1
After:  [1, 0, 2, 1]

Before: [1, 3, 0, 2]
5 3 1 2
After:  [1, 3, 0, 2]

Before: [3, 2, 0, 1]
1 2 0 3
After:  [3, 2, 0, 0]

Before: [3, 2, 2, 0]
14 2 3 3
After:  [3, 2, 2, 1]

Before: [2, 1, 2, 3]
15 3 0 2
After:  [2, 1, 2, 3]

Before: [2, 3, 2, 0]
14 2 3 2
After:  [2, 3, 1, 0]

Before: [0, 3, 3, 2]
5 3 1 2
After:  [0, 3, 0, 2]

Before: [0, 1, 2, 0]
7 1 2 1
After:  [0, 0, 2, 0]

Before: [3, 3, 2, 0]
3 1 2 2
After:  [3, 3, 2, 0]

Before: [2, 1, 2, 3]
7 1 2 0
After:  [0, 1, 2, 3]

Before: [1, 2, 2, 1]
4 0 2 2
After:  [1, 2, 0, 1]

Before: [0, 2, 3, 0]
8 0 0 2
After:  [0, 2, 0, 0]

Before: [2, 3, 2, 0]
11 2 1 3
After:  [2, 3, 2, 0]

Before: [2, 2, 2, 0]
2 0 2 0
After:  [4, 2, 2, 0]

Before: [1, 0, 2, 2]
2 3 2 1
After:  [1, 4, 2, 2]

Before: [0, 3, 1, 2]
13 0 2 2
After:  [0, 3, 0, 2]

Before: [1, 1, 2, 1]
4 0 2 0
After:  [0, 1, 2, 1]

Before: [0, 2, 1, 2]
8 0 0 2
After:  [0, 2, 0, 2]

Before: [3, 0, 2, 1]
9 3 2 0
After:  [1, 0, 2, 1]

Before: [1, 2, 2, 1]
4 0 2 1
After:  [1, 0, 2, 1]

Before: [0, 1, 2, 1]
14 2 3 2
After:  [0, 1, 1, 1]

Before: [1, 0, 2, 1]
2 2 2 1
After:  [1, 4, 2, 1]

Before: [1, 0, 2, 3]
4 0 2 1
After:  [1, 0, 2, 3]

Before: [3, 0, 0, 2]
15 0 3 3
After:  [3, 0, 0, 2]

Before: [2, 2, 2, 1]
9 3 2 0
After:  [1, 2, 2, 1]

Before: [1, 3, 3, 2]
5 3 1 0
After:  [0, 3, 3, 2]

Before: [2, 0, 3, 1]
0 2 3 2
After:  [2, 0, 1, 1]

Before: [3, 3, 0, 2]
15 1 3 1
After:  [3, 2, 0, 2]

Before: [1, 3, 3, 2]
5 3 1 2
After:  [1, 3, 0, 2]

Before: [0, 3, 1, 3]
6 2 2 3
After:  [0, 3, 1, 2]

Before: [1, 1, 2, 0]
7 1 2 0
After:  [0, 1, 2, 0]

Before: [3, 1, 1, 3]
6 2 2 1
After:  [3, 2, 1, 3]

Before: [3, 3, 0, 2]
5 3 1 1
After:  [3, 0, 0, 2]

Before: [0, 1, 1, 1]
13 0 1 1
After:  [0, 0, 1, 1]

Before: [0, 3, 2, 2]
5 3 1 3
After:  [0, 3, 2, 0]

Before: [0, 1, 2, 1]
7 1 2 2
After:  [0, 1, 0, 1]

Before: [0, 0, 2, 1]
8 0 0 1
After:  [0, 0, 2, 1]

Before: [1, 1, 3, 3]
10 0 3 2
After:  [1, 1, 1, 3]

Before: [0, 0, 1, 1]
8 0 0 0
After:  [0, 0, 1, 1]

Before: [1, 3, 3, 2]
15 1 3 3
After:  [1, 3, 3, 2]

Before: [1, 3, 2, 0]
3 1 2 2
After:  [1, 3, 2, 0]

Before: [2, 0, 2, 1]
1 1 0 3
After:  [2, 0, 2, 0]

Before: [3, 0, 0, 2]
1 2 0 3
After:  [3, 0, 0, 0]

Before: [2, 3, 2, 2]
15 1 0 2
After:  [2, 3, 2, 2]

Before: [0, 2, 3, 1]
13 0 2 0
After:  [0, 2, 3, 1]

Before: [2, 0, 3, 2]
1 1 0 1
After:  [2, 0, 3, 2]

Before: [2, 1, 2, 1]
14 2 3 3
After:  [2, 1, 2, 1]

Before: [3, 2, 2, 3]
15 3 1 3
After:  [3, 2, 2, 2]

Before: [1, 0, 2, 1]
4 0 2 2
After:  [1, 0, 0, 1]

Before: [3, 2, 1, 2]
15 0 3 2
After:  [3, 2, 2, 2]

Before: [1, 1, 2, 1]
14 2 3 1
After:  [1, 1, 2, 1]

Before: [0, 3, 2, 1]
9 3 2 3
After:  [0, 3, 2, 1]

Before: [2, 3, 2, 3]
3 3 2 0
After:  [2, 3, 2, 3]

Before: [1, 1, 2, 0]
7 1 2 2
After:  [1, 1, 0, 0]

Before: [0, 0, 0, 1]
13 0 3 0
After:  [0, 0, 0, 1]

Before: [1, 1, 2, 3]
4 0 2 2
After:  [1, 1, 0, 3]

Before: [0, 3, 2, 0]
13 0 2 2
After:  [0, 3, 0, 0]

Before: [3, 1, 2, 1]
9 3 2 2
After:  [3, 1, 1, 1]

Before: [3, 0, 0, 1]
1 2 0 3
After:  [3, 0, 0, 0]

Before: [2, 2, 2, 3]
0 2 1 2
After:  [2, 2, 0, 3]

Before: [0, 0, 3, 1]
8 0 0 2
After:  [0, 0, 0, 1]

Before: [0, 3, 1, 2]
5 3 1 0
After:  [0, 3, 1, 2]

Before: [0, 1, 2, 0]
14 2 3 2
After:  [0, 1, 1, 0]

Before: [0, 3, 2, 3]
3 1 2 1
After:  [0, 2, 2, 3]

Before: [0, 3, 0, 2]
5 3 1 3
After:  [0, 3, 0, 0]

Before: [2, 3, 3, 2]
5 3 1 0
After:  [0, 3, 3, 2]

Before: [0, 0, 3, 1]
8 0 0 0
After:  [0, 0, 3, 1]

Before: [0, 2, 2, 0]
8 0 0 3
After:  [0, 2, 2, 0]

Before: [3, 1, 1, 3]
6 2 2 3
After:  [3, 1, 1, 2]

Before: [0, 3, 3, 0]
8 0 0 0
After:  [0, 3, 3, 0]

Before: [2, 2, 2, 3]
10 1 3 2
After:  [2, 2, 2, 3]

Before: [2, 3, 1, 3]
6 2 2 0
After:  [2, 3, 1, 3]

Before: [2, 3, 2, 3]
3 3 2 2
After:  [2, 3, 2, 3]

Before: [0, 1, 2, 3]
8 0 0 0
After:  [0, 1, 2, 3]

Before: [2, 2, 0, 3]
10 0 3 3
After:  [2, 2, 0, 2]

Before: [3, 0, 0, 3]
1 1 0 3
After:  [3, 0, 0, 0]

Before: [0, 2, 2, 1]
14 2 3 3
After:  [0, 2, 2, 1]

Before: [1, 3, 2, 2]
11 2 1 3
After:  [1, 3, 2, 0]

Before: [3, 2, 1, 2]
15 0 3 3
After:  [3, 2, 1, 2]

Before: [0, 2, 1, 3]
6 2 2 3
After:  [0, 2, 1, 2]

Before: [3, 0, 2, 2]
2 3 2 1
After:  [3, 4, 2, 2]

Before: [3, 1, 0, 0]
1 2 0 0
After:  [0, 1, 0, 0]

Before: [0, 3, 3, 1]
13 0 2 1
After:  [0, 0, 3, 1]

Before: [0, 3, 2, 1]
13 0 3 1
After:  [0, 0, 2, 1]

Before: [0, 3, 2, 1]
9 3 2 0
After:  [1, 3, 2, 1]

Before: [0, 0, 2, 2]
2 2 2 2
After:  [0, 0, 4, 2]

Before: [0, 2, 2, 3]
8 0 0 2
After:  [0, 2, 0, 3]

Before: [1, 2, 2, 2]
4 0 2 1
After:  [1, 0, 2, 2]

Before: [3, 0, 3, 2]
1 1 0 2
After:  [3, 0, 0, 2]

Before: [1, 3, 2, 1]
9 3 2 0
After:  [1, 3, 2, 1]

Before: [0, 1, 1, 2]
13 0 1 2
After:  [0, 1, 0, 2]

Before: [1, 3, 2, 0]
2 2 2 1
After:  [1, 4, 2, 0]

Before: [2, 1, 2, 1]
7 1 2 3
After:  [2, 1, 2, 0]

Before: [2, 0, 2, 3]
3 3 2 1
After:  [2, 2, 2, 3]

Before: [2, 1, 2, 3]
7 1 2 1
After:  [2, 0, 2, 3]

Before: [3, 2, 2, 1]
15 0 1 2
After:  [3, 2, 2, 1]

Before: [1, 2, 2, 3]
4 0 2 1
After:  [1, 0, 2, 3]

Before: [2, 1, 2, 0]
7 1 2 2
After:  [2, 1, 0, 0]

Before: [3, 0, 0, 3]
1 2 0 1
After:  [3, 0, 0, 3]

Before: [3, 2, 2, 0]
3 0 2 3
After:  [3, 2, 2, 2]

Before: [2, 3, 2, 2]
11 2 1 2
After:  [2, 3, 0, 2]

Before: [2, 3, 2, 0]
11 2 1 2
After:  [2, 3, 0, 0]

Before: [1, 1, 1, 3]
10 0 3 3
After:  [1, 1, 1, 1]

Before: [1, 2, 2, 1]
9 3 2 3
After:  [1, 2, 2, 1]

Before: [3, 3, 3, 2]
5 3 1 3
After:  [3, 3, 3, 0]

Before: [0, 2, 2, 1]
9 3 2 1
After:  [0, 1, 2, 1]

Before: [2, 2, 2, 3]
3 3 2 0
After:  [2, 2, 2, 3]

Before: [0, 1, 2, 3]
3 3 2 3
After:  [0, 1, 2, 2]

Before: [2, 2, 3, 1]
0 2 3 3
After:  [2, 2, 3, 1]

Before: [0, 2, 2, 1]
9 3 2 2
After:  [0, 2, 1, 1]

Before: [0, 2, 2, 2]
2 2 2 3
After:  [0, 2, 2, 4]

Before: [3, 0, 1, 1]
6 2 2 3
After:  [3, 0, 1, 2]

Before: [0, 3, 2, 3]
11 2 1 3
After:  [0, 3, 2, 0]

Before: [1, 0, 2, 3]
10 0 3 2
After:  [1, 0, 1, 3]

Before: [1, 1, 2, 1]
9 3 2 0
After:  [1, 1, 2, 1]

Before: [1, 3, 2, 1]
3 1 2 3
After:  [1, 3, 2, 2]

Before: [2, 0, 3, 1]
0 2 3 3
After:  [2, 0, 3, 1]

Before: [1, 0, 2, 0]
4 0 2 3
After:  [1, 0, 2, 0]

Before: [0, 3, 2, 3]
3 1 2 0
After:  [2, 3, 2, 3]

Before: [2, 2, 2, 3]
2 0 2 3
After:  [2, 2, 2, 4]

Before: [2, 3, 3, 3]
10 0 3 3
After:  [2, 3, 3, 2]

Before: [0, 3, 0, 2]
5 3 1 1
After:  [0, 0, 0, 2]

Before: [3, 1, 2, 3]
7 1 2 3
After:  [3, 1, 2, 0]

Before: [0, 0, 2, 3]
2 2 2 1
After:  [0, 4, 2, 3]

Before: [3, 0, 1, 1]
1 1 0 2
After:  [3, 0, 0, 1]

Before: [2, 0, 2, 0]
1 1 0 0
After:  [0, 0, 2, 0]

Before: [1, 0, 0, 0]
12 0 2 0
After:  [0, 0, 0, 0]

Before: [0, 2, 1, 3]
10 1 3 3
After:  [0, 2, 1, 2]

Before: [2, 0, 1, 3]
15 3 0 1
After:  [2, 2, 1, 3]

Before: [2, 3, 1, 2]
5 3 1 0
After:  [0, 3, 1, 2]

Before: [1, 3, 0, 2]
12 0 2 2
After:  [1, 3, 0, 2]

Before: [0, 3, 2, 2]
11 2 1 3
After:  [0, 3, 2, 0]

Before: [3, 0, 0, 1]
1 2 0 2
After:  [3, 0, 0, 1]

Before: [2, 0, 0, 0]
1 1 0 1
After:  [2, 0, 0, 0]

Before: [0, 2, 1, 2]
13 0 1 1
After:  [0, 0, 1, 2]

Before: [1, 1, 2, 0]
4 0 2 3
After:  [1, 1, 2, 0]

Before: [1, 1, 2, 0]
4 0 2 1
After:  [1, 0, 2, 0]

Before: [2, 1, 2, 3]
15 3 0 0
After:  [2, 1, 2, 3]

Before: [2, 0, 0, 1]
1 1 0 2
After:  [2, 0, 0, 1]

Before: [1, 1, 2, 2]
2 3 2 3
After:  [1, 1, 2, 4]

Before: [0, 2, 2, 2]
0 2 1 1
After:  [0, 0, 2, 2]

Before: [1, 2, 0, 2]
12 0 2 3
After:  [1, 2, 0, 0]

Before: [3, 2, 3, 1]
0 2 3 3
After:  [3, 2, 3, 1]

Before: [1, 0, 0, 3]
12 0 2 3
After:  [1, 0, 0, 0]

Before: [1, 2, 2, 0]
4 0 2 2
After:  [1, 2, 0, 0]

Before: [1, 3, 2, 0]
4 0 2 1
After:  [1, 0, 2, 0]

Before: [2, 3, 2, 1]
3 1 2 3
After:  [2, 3, 2, 2]

Before: [2, 1, 2, 0]
14 2 3 3
After:  [2, 1, 2, 1]

Before: [2, 3, 2, 2]
5 3 1 0
After:  [0, 3, 2, 2]

Before: [3, 3, 2, 2]
3 0 2 0
After:  [2, 3, 2, 2]

Before: [0, 3, 2, 3]
3 1 2 3
After:  [0, 3, 2, 2]

Before: [1, 3, 2, 1]
9 3 2 2
After:  [1, 3, 1, 1]

Before: [2, 1, 2, 3]
7 1 2 3
After:  [2, 1, 2, 0]

Before: [0, 3, 2, 1]
3 1 2 2
After:  [0, 3, 2, 1]

Before: [0, 2, 1, 0]
13 0 1 3
After:  [0, 2, 1, 0]

Before: [0, 3, 1, 0]
8 0 0 0
After:  [0, 3, 1, 0]

Before: [1, 0, 0, 3]
10 0 3 0
After:  [1, 0, 0, 3]

Before: [1, 1, 0, 0]
12 0 2 3
After:  [1, 1, 0, 0]

Before: [3, 3, 2, 2]
5 3 1 2
After:  [3, 3, 0, 2]

Before: [0, 3, 2, 3]
13 0 1 3
After:  [0, 3, 2, 0]

Before: [1, 3, 1, 3]
10 2 3 1
After:  [1, 1, 1, 3]

Before: [1, 2, 2, 2]
2 1 2 0
After:  [4, 2, 2, 2]

Before: [0, 3, 2, 3]
3 3 2 2
After:  [0, 3, 2, 3]

Before: [1, 2, 0, 3]
12 0 2 1
After:  [1, 0, 0, 3]

Before: [3, 0, 2, 3]
3 0 2 1
After:  [3, 2, 2, 3]

Before: [0, 1, 3, 0]
13 0 1 1
After:  [0, 0, 3, 0]

Before: [1, 2, 2, 2]
2 3 2 1
After:  [1, 4, 2, 2]

Before: [3, 2, 1, 2]
6 2 2 1
After:  [3, 2, 1, 2]

Before: [2, 3, 1, 3]
10 0 3 0
After:  [2, 3, 1, 3]

Before: [3, 3, 2, 1]
14 2 3 3
After:  [3, 3, 2, 1]

Before: [2, 3, 3, 1]
0 2 3 0
After:  [1, 3, 3, 1]

Before: [1, 1, 0, 2]
12 0 2 0
After:  [0, 1, 0, 2]

Before: [0, 3, 0, 3]
8 0 0 1
After:  [0, 0, 0, 3]

Before: [1, 2, 3, 1]
0 2 3 1
After:  [1, 1, 3, 1]

Before: [2, 1, 2, 0]
14 2 3 2
After:  [2, 1, 1, 0]

Before: [0, 1, 2, 3]
7 1 2 3
After:  [0, 1, 2, 0]

Before: [3, 3, 3, 2]
5 3 1 1
After:  [3, 0, 3, 2]

Before: [2, 3, 2, 3]
11 2 1 1
After:  [2, 0, 2, 3]

Before: [2, 0, 0, 2]
1 1 0 1
After:  [2, 0, 0, 2]

Before: [3, 1, 2, 0]
3 0 2 1
After:  [3, 2, 2, 0]

Before: [1, 1, 2, 1]
7 1 2 3
After:  [1, 1, 2, 0]

Before: [2, 3, 0, 2]
15 1 3 3
After:  [2, 3, 0, 2]

Before: [1, 3, 2, 0]
14 2 3 3
After:  [1, 3, 2, 1]

Before: [3, 3, 2, 0]
14 2 3 3
After:  [3, 3, 2, 1]

Before: [3, 3, 2, 2]
11 2 1 2
After:  [3, 3, 0, 2]

Before: [1, 2, 2, 3]
0 2 1 1
After:  [1, 0, 2, 3]

Before: [3, 2, 3, 3]
10 1 3 2
After:  [3, 2, 2, 3]

Before: [2, 1, 2, 2]
7 1 2 0
After:  [0, 1, 2, 2]

Before: [1, 1, 1, 1]
6 2 2 1
After:  [1, 2, 1, 1]

Before: [3, 1, 2, 2]
3 0 2 3
After:  [3, 1, 2, 2]

Before: [1, 3, 2, 0]
11 2 1 0
After:  [0, 3, 2, 0]

Before: [2, 3, 0, 0]
15 1 0 1
After:  [2, 2, 0, 0]

Before: [3, 3, 3, 2]
5 3 1 0
After:  [0, 3, 3, 2]

Before: [0, 3, 2, 0]
11 2 1 1
After:  [0, 0, 2, 0]

Before: [0, 3, 2, 2]
15 1 3 2
After:  [0, 3, 2, 2]

Before: [0, 1, 2, 1]
13 0 1 1
After:  [0, 0, 2, 1]

Before: [3, 1, 0, 2]
1 2 0 2
After:  [3, 1, 0, 2]

Before: [1, 2, 0, 3]
12 0 2 3
After:  [1, 2, 0, 0]

Before: [3, 3, 1, 0]
6 2 2 3
After:  [3, 3, 1, 2]

Before: [1, 1, 3, 1]
0 2 3 0
After:  [1, 1, 3, 1]

Before: [3, 1, 2, 1]
7 1 2 3
After:  [3, 1, 2, 0]

Before: [0, 1, 1, 3]
6 2 2 2
After:  [0, 1, 2, 3]

Before: [1, 2, 2, 3]
3 3 2 0
After:  [2, 2, 2, 3]

Before: [3, 0, 3, 0]
1 1 0 3
After:  [3, 0, 3, 0]

Before: [1, 0, 2, 1]
4 0 2 3
After:  [1, 0, 2, 0]

Before: [3, 0, 0, 2]
1 1 0 2
After:  [3, 0, 0, 2]

Before: [3, 0, 1, 0]
6 2 2 2
After:  [3, 0, 2, 0]

Before: [0, 2, 2, 3]
3 3 2 0
After:  [2, 2, 2, 3]

Before: [1, 3, 0, 3]
10 0 3 3
After:  [1, 3, 0, 1]

Before: [3, 1, 1, 3]
10 2 3 1
After:  [3, 1, 1, 3]

Before: [0, 1, 2, 3]
2 2 2 1
After:  [0, 4, 2, 3]

Before: [2, 3, 2, 1]
3 1 2 2
After:  [2, 3, 2, 1]

Before: [3, 3, 1, 2]
6 2 2 1
After:  [3, 2, 1, 2]

Before: [3, 0, 2, 3]
3 3 2 2
After:  [3, 0, 2, 3]

Before: [2, 1, 2, 3]
10 0 3 3
After:  [2, 1, 2, 2]

Before: [2, 2, 0, 3]
10 1 3 3
After:  [2, 2, 0, 2]

Before: [3, 3, 2, 0]
14 2 3 1
After:  [3, 1, 2, 0]

Before: [0, 3, 2, 0]
3 1 2 3
After:  [0, 3, 2, 2]

Before: [0, 2, 3, 0]
13 0 1 1
After:  [0, 0, 3, 0]

Before: [0, 2, 2, 2]
13 0 3 0
After:  [0, 2, 2, 2]

Before: [1, 1, 0, 1]
12 0 2 1
After:  [1, 0, 0, 1]

Before: [0, 3, 2, 0]
11 2 1 3
After:  [0, 3, 2, 0]

Before: [2, 1, 2, 1]
7 1 2 2
After:  [2, 1, 0, 1]

Before: [1, 3, 2, 0]
11 2 1 2
After:  [1, 3, 0, 0]

Before: [1, 3, 2, 0]
11 2 1 1
After:  [1, 0, 2, 0]

Before: [3, 0, 2, 1]
14 2 3 3
After:  [3, 0, 2, 1]

Before: [1, 0, 0, 1]
12 0 2 2
After:  [1, 0, 0, 1]

Before: [1, 1, 2, 2]
2 3 2 2
After:  [1, 1, 4, 2]

Before: [1, 1, 2, 1]
14 2 3 2
After:  [1, 1, 1, 1]

Before: [0, 3, 2, 0]
13 0 2 3
After:  [0, 3, 2, 0]

Before: [1, 3, 2, 3]
11 2 1 2
After:  [1, 3, 0, 3]

Before: [2, 1, 2, 3]
15 3 0 3
After:  [2, 1, 2, 2]

Before: [1, 3, 0, 3]
12 0 2 1
After:  [1, 0, 0, 3]

Before: [3, 3, 2, 1]
11 2 1 1
After:  [3, 0, 2, 1]

Before: [0, 3, 3, 3]
13 0 1 2
After:  [0, 3, 0, 3]

Before: [1, 1, 2, 3]
4 0 2 3
After:  [1, 1, 2, 0]

Before: [1, 2, 2, 0]
2 2 2 0
After:  [4, 2, 2, 0]

Before: [1, 0, 2, 2]
4 0 2 3
After:  [1, 0, 2, 0]

Before: [2, 3, 3, 2]
5 3 1 3
After:  [2, 3, 3, 0]

Before: [1, 0, 2, 1]
9 3 2 0
After:  [1, 0, 2, 1]

Before: [0, 3, 3, 0]
13 0 2 0
After:  [0, 3, 3, 0]

Before: [3, 1, 0, 3]
1 2 0 3
After:  [3, 1, 0, 0]

Before: [2, 2, 1, 3]
10 2 3 1
After:  [2, 1, 1, 3]

Before: [3, 1, 2, 0]
3 0 2 2
After:  [3, 1, 2, 0]

Before: [2, 0, 1, 0]
6 2 2 3
After:  [2, 0, 1, 2]

Before: [0, 2, 0, 0]
13 0 1 1
After:  [0, 0, 0, 0]

Before: [0, 2, 2, 1]
2 2 2 1
After:  [0, 4, 2, 1]

Before: [2, 3, 3, 1]
0 2 3 1
After:  [2, 1, 3, 1]

Before: [3, 1, 2, 1]
14 2 3 2
After:  [3, 1, 1, 1]

Before: [0, 2, 2, 3]
0 2 1 2
After:  [0, 2, 0, 3]

Before: [3, 1, 2, 1]
7 1 2 0
After:  [0, 1, 2, 1]

Before: [2, 1, 1, 3]
6 2 2 0
After:  [2, 1, 1, 3]

Before: [3, 3, 2, 1]
14 2 3 0
After:  [1, 3, 2, 1]

Before: [1, 2, 0, 2]
12 0 2 2
After:  [1, 2, 0, 2]

Before: [0, 1, 0, 3]
8 0 0 3
After:  [0, 1, 0, 0]

Before: [1, 3, 1, 2]
5 3 1 1
After:  [1, 0, 1, 2]

Before: [2, 1, 1, 0]
6 2 2 1
After:  [2, 2, 1, 0]

Before: [1, 2, 2, 3]
4 0 2 2
After:  [1, 2, 0, 3]

Before: [2, 3, 2, 1]
9 3 2 3
After:  [2, 3, 2, 1]

Before: [1, 0, 2, 0]
14 2 3 3
After:  [1, 0, 2, 1]

Before: [1, 0, 1, 3]
6 2 2 2
After:  [1, 0, 2, 3]

Before: [1, 1, 0, 3]
12 0 2 1
After:  [1, 0, 0, 3]

Before: [1, 1, 2, 2]
4 0 2 3
After:  [1, 1, 2, 0]

Before: [1, 0, 2, 1]
9 3 2 1
After:  [1, 1, 2, 1]

Before: [1, 3, 2, 1]
4 0 2 1
After:  [1, 0, 2, 1]

Before: [3, 1, 2, 0]
3 0 2 0
After:  [2, 1, 2, 0]

Before: [3, 3, 2, 0]
11 2 1 0
After:  [0, 3, 2, 0]

Before: [0, 3, 2, 2]
8 0 0 0
After:  [0, 3, 2, 2]

Before: [3, 2, 2, 0]
14 2 3 0
After:  [1, 2, 2, 0]

Before: [1, 2, 2, 3]
2 1 2 3
After:  [1, 2, 2, 4]

Before: [3, 2, 3, 0]
15 0 1 3
After:  [3, 2, 3, 2]

Before: [3, 1, 1, 2]
15 0 3 2
After:  [3, 1, 2, 2]

Before: [2, 3, 1, 3]
6 2 2 3
After:  [2, 3, 1, 2]

Before: [1, 1, 2, 3]
4 0 2 1
After:  [1, 0, 2, 3]

Before: [2, 2, 1, 0]
6 2 2 0
After:  [2, 2, 1, 0]

Before: [3, 1, 2, 1]
7 1 2 2
After:  [3, 1, 0, 1]

Before: [3, 3, 1, 2]
5 3 1 2
After:  [3, 3, 0, 2]

Before: [0, 3, 2, 1]
11 2 1 2
After:  [0, 3, 0, 1]

Before: [1, 3, 0, 2]
5 3 1 1
After:  [1, 0, 0, 2]

Before: [2, 1, 0, 3]
15 3 0 3
After:  [2, 1, 0, 2]

Before: [3, 0, 3, 1]
0 2 3 0
After:  [1, 0, 3, 1]

Before: [1, 1, 2, 3]
7 1 2 3
After:  [1, 1, 2, 0]

Before: [1, 3, 2, 3]
3 1 2 3
After:  [1, 3, 2, 2]

Before: [1, 2, 2, 1]
9 3 2 1
After:  [1, 1, 2, 1]

Before: [0, 0, 0, 3]
13 0 3 0
After:  [0, 0, 0, 3]

Before: [1, 0, 2, 3]
4 0 2 3
After:  [1, 0, 2, 0]

Before: [1, 3, 2, 2]
2 3 2 3
After:  [1, 3, 2, 4]

Before: [1, 0, 2, 1]
14 2 3 3
After:  [1, 0, 2, 1]

Before: [0, 1, 2, 1]
9 3 2 0
After:  [1, 1, 2, 1]

Before: [0, 3, 3, 2]
5 3 1 0
After:  [0, 3, 3, 2]

Before: [3, 2, 1, 0]
6 2 2 3
After:  [3, 2, 1, 2]

Before: [0, 3, 2, 3]
11 2 1 1
After:  [0, 0, 2, 3]

Before: [3, 0, 0, 1]
1 2 0 0
After:  [0, 0, 0, 1]

Before: [3, 2, 2, 3]
2 2 2 1
After:  [3, 4, 2, 3]

Before: [2, 0, 2, 3]
2 0 2 0
After:  [4, 0, 2, 3]

Before: [0, 2, 1, 3]
8 0 0 3
After:  [0, 2, 1, 0]

Before: [3, 2, 0, 0]
15 0 1 2
After:  [3, 2, 2, 0]

Before: [0, 1, 0, 2]
13 0 3 0
After:  [0, 1, 0, 2]

Before: [0, 3, 1, 3]
13 0 2 0
After:  [0, 3, 1, 3]

Before: [2, 3, 0, 2]
5 3 1 0
After:  [0, 3, 0, 2]

Before: [2, 3, 2, 1]
9 3 2 0
After:  [1, 3, 2, 1]

Before: [0, 3, 3, 1]
13 0 3 1
After:  [0, 0, 3, 1]

Before: [1, 3, 2, 0]
14 2 3 1
After:  [1, 1, 2, 0]

Before: [1, 3, 2, 1]
4 0 2 2
After:  [1, 3, 0, 1]

Before: [0, 0, 2, 1]
13 0 2 3
After:  [0, 0, 2, 0]

Before: [1, 1, 3, 1]
0 2 3 1
After:  [1, 1, 3, 1]

Before: [3, 3, 2, 2]
15 1 3 2
After:  [3, 3, 2, 2]

Before: [1, 3, 2, 2]
2 2 2 3
After:  [1, 3, 2, 4]

Before: [1, 3, 0, 3]
10 0 3 1
After:  [1, 1, 0, 3]

Before: [3, 0, 2, 1]
1 1 0 3
After:  [3, 0, 2, 0]

Before: [3, 1, 2, 1]
9 3 2 3
After:  [3, 1, 2, 1]

Before: [1, 2, 2, 3]
0 2 1 3
After:  [1, 2, 2, 0]

Before: [2, 2, 2, 1]
2 1 2 3
After:  [2, 2, 2, 4]

Before: [1, 3, 2, 1]
4 0 2 0
After:  [0, 3, 2, 1]

Before: [1, 1, 2, 1]
7 1 2 2
After:  [1, 1, 0, 1]

Before: [2, 3, 2, 2]
3 1 2 3
After:  [2, 3, 2, 2]

Before: [0, 1, 2, 1]
9 3 2 1
After:  [0, 1, 2, 1]

Before: [3, 0, 0, 3]
1 2 0 0
After:  [0, 0, 0, 3]

Before: [3, 0, 1, 1]
6 2 2 2
After:  [3, 0, 2, 1]

Before: [1, 1, 0, 2]
12 0 2 2
After:  [1, 1, 0, 2]

Before: [2, 3, 1, 3]
6 2 2 2
After:  [2, 3, 2, 3]

Before: [0, 3, 2, 3]
11 2 1 0
After:  [0, 3, 2, 3]

Before: [1, 2, 2, 3]
2 2 2 0
After:  [4, 2, 2, 3]

Before: [0, 2, 0, 2]
13 0 1 2
After:  [0, 2, 0, 2]

Before: [1, 3, 2, 3]
4 0 2 3
After:  [1, 3, 2, 0]

Before: [0, 2, 3, 3]
13 0 3 2
After:  [0, 2, 0, 3]

Before: [0, 3, 1, 2]
5 3 1 3
After:  [0, 3, 1, 0]

Before: [1, 0, 2, 1]
14 2 3 0
After:  [1, 0, 2, 1]

Before: [2, 2, 2, 0]
0 2 1 1
After:  [2, 0, 2, 0]

Before: [2, 3, 1, 2]
5 3 1 3
After:  [2, 3, 1, 0]

Before: [0, 2, 0, 1]
13 0 1 0
After:  [0, 2, 0, 1]

Before: [2, 2, 3, 3]
15 3 1 2
After:  [2, 2, 2, 3]

Before: [0, 1, 2, 3]
2 2 2 0
After:  [4, 1, 2, 3]

Before: [3, 1, 2, 0]
7 1 2 0
After:  [0, 1, 2, 0]

Before: [1, 2, 0, 2]
12 0 2 0
After:  [0, 2, 0, 2]

Before: [0, 0, 0, 0]
8 0 0 3
After:  [0, 0, 0, 0]

Before: [0, 2, 3, 2]
8 0 0 3
After:  [0, 2, 3, 0]

Before: [0, 1, 2, 2]
2 3 2 0
After:  [4, 1, 2, 2]

Before: [1, 3, 2, 0]
14 2 3 0
After:  [1, 3, 2, 0]

Before: [1, 2, 2, 3]
0 2 1 2
After:  [1, 2, 0, 3]

Before: [0, 2, 3, 3]
13 0 2 3
After:  [0, 2, 3, 0]

Before: [3, 3, 2, 0]
11 2 1 2
After:  [3, 3, 0, 0]

Before: [0, 3, 3, 2]
8 0 0 3
After:  [0, 3, 3, 0]

Before: [2, 1, 1, 0]
6 2 2 3
After:  [2, 1, 1, 2]

Before: [3, 3, 1, 1]
6 2 2 0
After:  [2, 3, 1, 1]

Before: [1, 1, 2, 3]
7 1 2 1
After:  [1, 0, 2, 3]

Before: [0, 1, 0, 1]
13 0 1 2
After:  [0, 1, 0, 1]

Before: [0, 1, 3, 1]
8 0 0 3
After:  [0, 1, 3, 0]

Before: [3, 3, 2, 0]
11 2 1 1
After:  [3, 0, 2, 0]

Before: [0, 1, 0, 0]
8 0 0 0
After:  [0, 1, 0, 0]

Before: [0, 2, 3, 0]
8 0 0 3
After:  [0, 2, 3, 0]

Before: [3, 0, 3, 2]
1 1 0 0
After:  [0, 0, 3, 2]

Before: [1, 0, 3, 1]
0 2 3 3
After:  [1, 0, 3, 1]

Before: [2, 3, 2, 3]
11 2 1 3
After:  [2, 3, 2, 0]

Before: [1, 1, 1, 1]
6 2 2 2
After:  [1, 1, 2, 1]

Before: [2, 3, 2, 2]
5 3 1 3
After:  [2, 3, 2, 0]

Before: [2, 3, 2, 1]
9 3 2 2
After:  [2, 3, 1, 1]

Before: [0, 2, 3, 1]
13 0 1 0
After:  [0, 2, 3, 1]

Before: [1, 0, 1, 3]
10 2 3 2
After:  [1, 0, 1, 3]

Before: [0, 3, 1, 2]
5 3 1 1
After:  [0, 0, 1, 2]

Before: [3, 0, 0, 3]
1 1 0 2
After:  [3, 0, 0, 3]

Before: [2, 3, 2, 1]
11 2 1 3
After:  [2, 3, 2, 0]

Before: [3, 2, 2, 1]
9 3 2 0
After:  [1, 2, 2, 1]

Before: [2, 2, 1, 2]
6 2 2 1
After:  [2, 2, 1, 2]

Before: [2, 3, 2, 3]
11 2 1 0
After:  [0, 3, 2, 3]

Before: [1, 3, 2, 0]
4 0 2 0
After:  [0, 3, 2, 0]

Before: [3, 1, 2, 2]
7 1 2 0
After:  [0, 1, 2, 2]

Before: [3, 1, 2, 3]
7 1 2 0
After:  [0, 1, 2, 3]

Before: [2, 3, 2, 3]
10 0 3 0
After:  [2, 3, 2, 3]

Before: [3, 2, 2, 3]
0 2 1 1
After:  [3, 0, 2, 3]

Before: [2, 0, 2, 0]
1 1 0 1
After:  [2, 0, 2, 0]

Before: [0, 3, 0, 2]
5 3 1 2
After:  [0, 3, 0, 2]

Before: [2, 2, 2, 1]
9 3 2 2
After:  [2, 2, 1, 1]

Before: [1, 1, 0, 1]
12 0 2 0
After:  [0, 1, 0, 1]

Before: [1, 0, 2, 1]
9 3 2 3
After:  [1, 0, 2, 1]

Before: [3, 2, 2, 3]
0 2 1 2
After:  [3, 2, 0, 3]

Before: [3, 0, 2, 2]
2 3 2 3
After:  [3, 0, 2, 4]

Before: [1, 0, 2, 2]
4 0 2 0
After:  [0, 0, 2, 2]

Before: [3, 3, 2, 2]
11 2 1 1
After:  [3, 0, 2, 2]

Before: [0, 1, 3, 1]
0 2 3 3
After:  [0, 1, 3, 1]

Before: [0, 0, 1, 0]
8 0 0 1
After:  [0, 0, 1, 0]

Before: [2, 0, 2, 1]
9 3 2 0
After:  [1, 0, 2, 1]

Before: [3, 0, 2, 2]
1 1 0 2
After:  [3, 0, 0, 2]

Before: [3, 3, 0, 1]
1 2 0 2
After:  [3, 3, 0, 1]

Before: [3, 2, 3, 3]
10 1 3 3
After:  [3, 2, 3, 2]

Before: [2, 3, 3, 1]
0 2 3 2
After:  [2, 3, 1, 1]

Before: [3, 1, 2, 2]
7 1 2 3
After:  [3, 1, 2, 0]

Before: [0, 3, 0, 3]
8 0 0 3
After:  [0, 3, 0, 0]

Before: [3, 0, 2, 2]
2 2 2 0
After:  [4, 0, 2, 2]

Before: [2, 3, 3, 3]
15 3 0 3
After:  [2, 3, 3, 2]

Before: [0, 2, 0, 1]
13 0 3 2
After:  [0, 2, 0, 1]

Before: [1, 2, 0, 3]
15 3 1 0
After:  [2, 2, 0, 3]

Before: [2, 2, 2, 2]
0 2 1 0
After:  [0, 2, 2, 2]

Before: [2, 0, 3, 1]
1 1 0 0
After:  [0, 0, 3, 1]

Before: [0, 0, 2, 1]
14 2 3 1
After:  [0, 1, 2, 1]

Before: [2, 2, 2, 1]
2 0 2 2
After:  [2, 2, 4, 1]

Before: [0, 3, 2, 1]
9 3 2 2
After:  [0, 3, 1, 1]

Before: [0, 3, 2, 2]
5 3 1 1
After:  [0, 0, 2, 2]

Before: [1, 2, 2, 2]
4 0 2 2
After:  [1, 2, 0, 2]

Before: [1, 1, 1, 3]
10 2 3 3
After:  [1, 1, 1, 1]

Before: [0, 2, 1, 1]
13 0 2 0
After:  [0, 2, 1, 1]

Before: [0, 3, 2, 2]
11 2 1 0
After:  [0, 3, 2, 2]

Before: [0, 2, 1, 2]
8 0 0 3
After:  [0, 2, 1, 0]

Before: [0, 3, 2, 2]
15 1 3 1
After:  [0, 2, 2, 2]

Before: [3, 0, 2, 0]
2 2 2 3
After:  [3, 0, 2, 4]

Before: [2, 2, 3, 3]
10 0 3 3
After:  [2, 2, 3, 2]

Before: [0, 2, 0, 3]
8 0 0 2
After:  [0, 2, 0, 3]

Before: [2, 2, 1, 3]
6 2 2 3
After:  [2, 2, 1, 2]

Before: [1, 2, 2, 0]
14 2 3 1
After:  [1, 1, 2, 0]

Before: [0, 3, 2, 1]
11 2 1 0
After:  [0, 3, 2, 1]

Before: [3, 3, 2, 1]
11 2 1 2
After:  [3, 3, 0, 1]

Before: [2, 3, 1, 3]
10 0 3 2
After:  [2, 3, 2, 3]

Before: [3, 1, 1, 1]
6 2 2 2
After:  [3, 1, 2, 1]

Before: [3, 2, 2, 0]
0 2 1 2
After:  [3, 2, 0, 0]

Before: [1, 3, 0, 2]
12 0 2 3
After:  [1, 3, 0, 0]

Before: [2, 3, 0, 2]
5 3 1 3
After:  [2, 3, 0, 0]

Before: [0, 1, 1, 0]
13 0 2 0
After:  [0, 1, 1, 0]

Before: [3, 3, 2, 1]
11 2 1 3
After:  [3, 3, 2, 0]

Before: [0, 1, 1, 3]
13 0 2 0
After:  [0, 1, 1, 3]

Before: [3, 3, 2, 3]
11 2 1 0
After:  [0, 3, 2, 3]

Before: [1, 1, 2, 1]
9 3 2 1
After:  [1, 1, 2, 1]

Before: [1, 1, 2, 1]
7 1 2 1
After:  [1, 0, 2, 1]

Before: [3, 2, 2, 3]
10 1 3 3
After:  [3, 2, 2, 2]

Before: [1, 2, 2, 3]
4 0 2 3
After:  [1, 2, 2, 0]

Before: [1, 3, 2, 3]
11 2 1 3
After:  [1, 3, 2, 0]

Before: [0, 0, 2, 1]
13 0 3 1
After:  [0, 0, 2, 1]

Before: [0, 1, 2, 0]
7 1 2 2
After:  [0, 1, 0, 0]

Before: [0, 3, 1, 3]
10 2 3 0
After:  [1, 3, 1, 3]

Before: [1, 1, 2, 2]
4 0 2 2
After:  [1, 1, 0, 2]

Before: [0, 1, 2, 3]
3 3 2 0
After:  [2, 1, 2, 3]

Before: [2, 0, 1, 2]
6 2 2 0
After:  [2, 0, 1, 2]

Before: [3, 0, 1, 2]
1 1 0 0
After:  [0, 0, 1, 2]

Before: [1, 2, 1, 3]
6 2 2 0
After:  [2, 2, 1, 3]

Before: [2, 3, 2, 0]
11 2 1 1
After:  [2, 0, 2, 0]

Before: [2, 3, 1, 1]
6 2 2 1
After:  [2, 2, 1, 1]

Before: [1, 0, 2, 1]
9 3 2 2
After:  [1, 0, 1, 1]

Before: [2, 3, 1, 3]
10 2 3 0
After:  [1, 3, 1, 3]

Before: [1, 2, 2, 1]
9 3 2 2
After:  [1, 2, 1, 1]

Before: [1, 3, 0, 1]
12 0 2 1
After:  [1, 0, 0, 1]

Before: [1, 2, 1, 3]
10 0 3 1
After:  [1, 1, 1, 3]

Before: [3, 0, 1, 3]
6 2 2 0
After:  [2, 0, 1, 3]

Before: [2, 3, 1, 3]
10 2 3 2
After:  [2, 3, 1, 3]

Before: [0, 1, 2, 1]
9 3 2 2
After:  [0, 1, 1, 1]

Before: [0, 3, 1, 2]
5 3 1 2
After:  [0, 3, 0, 2]

Before: [0, 2, 2, 1]
9 3 2 3
After:  [0, 2, 2, 1]

Before: [1, 3, 2, 2]
5 3 1 0
After:  [0, 3, 2, 2]

Before: [0, 1, 2, 0]
2 2 2 3
After:  [0, 1, 2, 4]

Before: [0, 3, 2, 3]
11 2 1 2
After:  [0, 3, 0, 3]

Before: [1, 3, 2, 0]
2 2 2 0
After:  [4, 3, 2, 0]

Before: [0, 1, 2, 3]
7 1 2 0
After:  [0, 1, 2, 3]

Before: [0, 1, 2, 1]
14 2 3 3
After:  [0, 1, 2, 1]

Before: [3, 3, 2, 0]
11 2 1 3
After:  [3, 3, 2, 0]

Before: [1, 3, 2, 1]
11 2 1 1
After:  [1, 0, 2, 1]

Before: [3, 3, 3, 2]
15 0 3 0
After:  [2, 3, 3, 2]

Before: [3, 3, 2, 2]
5 3 1 3
After:  [3, 3, 2, 0]

Before: [1, 0, 0, 2]
12 0 2 1
After:  [1, 0, 0, 2]

Before: [1, 0, 0, 3]
12 0 2 1
After:  [1, 0, 0, 3]

Before: [1, 3, 0, 2]
5 3 1 3
After:  [1, 3, 0, 0]

Before: [1, 1, 2, 3]
4 0 2 0
After:  [0, 1, 2, 3]

Before: [1, 0, 2, 0]
14 2 3 0
After:  [1, 0, 2, 0]

Before: [3, 3, 0, 3]
1 2 0 0
After:  [0, 3, 0, 3]

Before: [3, 3, 2, 1]
3 0 2 1
After:  [3, 2, 2, 1]

Before: [1, 3, 2, 0]
4 0 2 2
After:  [1, 3, 0, 0]

Before: [3, 2, 0, 1]
15 0 1 1
After:  [3, 2, 0, 1]

Before: [0, 3, 2, 3]
2 2 2 0
After:  [4, 3, 2, 3]

Before: [1, 0, 0, 0]
12 0 2 1
After:  [1, 0, 0, 0]

Before: [0, 0, 0, 1]
8 0 0 3
After:  [0, 0, 0, 0]

Before: [1, 3, 2, 3]
4 0 2 2
After:  [1, 3, 0, 3]

Before: [1, 3, 0, 0]
12 0 2 2
After:  [1, 3, 0, 0]

Before: [2, 2, 0, 3]
10 0 3 1
After:  [2, 2, 0, 3]

Before: [3, 0, 3, 3]
1 1 0 2
After:  [3, 0, 0, 3]

Before: [3, 3, 2, 2]
11 2 1 0
After:  [0, 3, 2, 2]

Before: [1, 2, 1, 3]
10 2 3 0
After:  [1, 2, 1, 3]

Before: [3, 3, 2, 3]
11 2 1 3
After:  [3, 3, 2, 0]

Before: [3, 2, 2, 0]
0 2 1 3
After:  [3, 2, 2, 0]

Before: [0, 2, 3, 1]
8 0 0 0
After:  [0, 2, 3, 1]

Before: [3, 0, 1, 2]
1 1 0 1
After:  [3, 0, 1, 2]

Before: [1, 1, 3, 1]
0 2 3 2
After:  [1, 1, 1, 1]

Before: [1, 2, 0, 0]
12 0 2 2
After:  [1, 2, 0, 0]

Before: [3, 0, 0, 0]
1 2 0 2
After:  [3, 0, 0, 0]

Before: [2, 1, 2, 3]
3 3 2 3
After:  [2, 1, 2, 2]

Before: [0, 2, 2, 0]
14 2 3 1
After:  [0, 1, 2, 0]

Before: [2, 3, 1, 2]
5 3 1 2
After:  [2, 3, 0, 2]

Before: [2, 2, 0, 3]
15 3 0 0
After:  [2, 2, 0, 3]

Before: [0, 2, 3, 2]
8 0 0 0
After:  [0, 2, 3, 2]

Before: [1, 3, 2, 1]
11 2 1 3
After:  [1, 3, 2, 0]

Before: [2, 1, 2, 1]
9 3 2 0
After:  [1, 1, 2, 1]

Before: [2, 2, 1, 3]
6 2 2 2
After:  [2, 2, 2, 3]

Before: [2, 3, 2, 1]
14 2 3 0
After:  [1, 3, 2, 1]

Before: [1, 3, 1, 3]
10 2 3 0
After:  [1, 3, 1, 3]

Before: [3, 3, 0, 2]
5 3 1 2
After:  [3, 3, 0, 2]

Before: [0, 3, 2, 3]
13 0 2 1
After:  [0, 0, 2, 3]

Before: [1, 0, 1, 1]
6 2 2 2
After:  [1, 0, 2, 1]

Before: [3, 3, 2, 2]
5 3 1 0
After:  [0, 3, 2, 2]

Before: [2, 1, 2, 1]
7 1 2 0
After:  [0, 1, 2, 1]

Before: [1, 1, 0, 0]
12 0 2 1
After:  [1, 0, 0, 0]

Before: [3, 3, 1, 0]
6 2 2 1
After:  [3, 2, 1, 0]

Before: [0, 1, 2, 0]
13 0 2 0
After:  [0, 1, 2, 0]

Before: [3, 3, 2, 0]
3 0 2 2
After:  [3, 3, 2, 0]

Before: [0, 1, 2, 1]
14 2 3 0
After:  [1, 1, 2, 1]

Before: [2, 3, 3, 0]
15 1 0 1
After:  [2, 2, 3, 0]

Before: [3, 2, 2, 2]
2 3 2 1
After:  [3, 4, 2, 2]

Before: [2, 2, 2, 3]
0 2 1 3
After:  [2, 2, 2, 0]

Before: [3, 0, 2, 2]
1 1 0 1
After:  [3, 0, 2, 2]

Before: [1, 2, 2, 0]
4 0 2 1
After:  [1, 0, 2, 0]

Before: [3, 3, 2, 0]
2 2 2 3
After:  [3, 3, 2, 4]

Before: [3, 2, 1, 3]
15 0 1 1
After:  [3, 2, 1, 3]

Before: [1, 3, 0, 0]
12 0 2 1
After:  [1, 0, 0, 0]

Before: [3, 3, 2, 3]
11 2 1 1
After:  [3, 0, 2, 3]

Before: [2, 0, 1, 1]
6 2 2 1
After:  [2, 2, 1, 1]

Before: [2, 1, 2, 1]
2 0 2 2
After:  [2, 1, 4, 1]

Before: [1, 0, 2, 3]
4 0 2 0
After:  [0, 0, 2, 3]

Before: [0, 3, 2, 1]
14 2 3 0
After:  [1, 3, 2, 1]

Before: [3, 2, 1, 3]
15 3 1 2
After:  [3, 2, 2, 3]

Before: [2, 0, 3, 3]
10 0 3 2
After:  [2, 0, 2, 3]

Before: [3, 0, 0, 2]
1 1 0 0
After:  [0, 0, 0, 2]

Before: [1, 3, 0, 3]
12 0 2 3
After:  [1, 3, 0, 0]

Before: [0, 1, 1, 2]
8 0 0 0
After:  [0, 1, 1, 2]

Before: [0, 3, 1, 1]
6 2 2 2
After:  [0, 3, 2, 1]

Before: [3, 3, 2, 2]
2 2 2 2
After:  [3, 3, 4, 2]

Before: [0, 3, 2, 3]
13 0 3 1
After:  [0, 0, 2, 3]

Before: [0, 1, 2, 2]
7 1 2 3
After:  [0, 1, 2, 0]

Before: [2, 2, 2, 1]
0 2 1 3
After:  [2, 2, 2, 0]

Before: [2, 3, 0, 2]
5 3 1 1
After:  [2, 0, 0, 2]

Before: [3, 2, 3, 0]
15 0 1 1
After:  [3, 2, 3, 0]

Before: [0, 3, 2, 2]
11 2 1 1
After:  [0, 0, 2, 2]

Before: [1, 1, 1, 3]
10 2 3 2
After:  [1, 1, 1, 3]

Before: [1, 0, 3, 1]
0 2 3 2
After:  [1, 0, 1, 1]

Before: [0, 3, 3, 1]
13 0 2 3
After:  [0, 3, 3, 0]

Before: [3, 2, 2, 1]
14 2 3 3
After:  [3, 2, 2, 1]

Before: [0, 0, 2, 3]
8 0 0 1
After:  [0, 0, 2, 3]

Before: [0, 3, 3, 3]
13 0 3 3
After:  [0, 3, 3, 0]

Before: [1, 3, 2, 3]
11 2 1 0
After:  [0, 3, 2, 3]

Before: [3, 0, 0, 1]
1 1 0 3
After:  [3, 0, 0, 0]

Before: [0, 3, 1, 1]
8 0 0 3
After:  [0, 3, 1, 0]

Before: [0, 0, 2, 3]
13 0 2 2
After:  [0, 0, 0, 3]

Before: [3, 1, 3, 1]
0 2 3 0
After:  [1, 1, 3, 1]

Before: [3, 2, 2, 2]
3 0 2 2
After:  [3, 2, 2, 2]

Before: [1, 3, 0, 3]
12 0 2 2
After:  [1, 3, 0, 3]

Before: [1, 3, 2, 1]
14 2 3 0
After:  [1, 3, 2, 1]

Before: [2, 2, 2, 2]
2 2 2 3
After:  [2, 2, 2, 4]

Before: [2, 1, 1, 2]
6 2 2 2
After:  [2, 1, 2, 2]

Before: [2, 0, 3, 3]
1 1 0 1
After:  [2, 0, 3, 3]

Before: [3, 2, 2, 3]
15 0 1 2
After:  [3, 2, 2, 3]
observations


@input_instructions = <<-instructions
4 0 2 0
13 2 0 2
2 2 3 2
4 3 2 3
3 3 2 2
13 2 1 2
6 2 1 1
10 1 2 3
4 2 3 0
13 1 0 1
2 1 1 1
13 3 0 2
2 2 1 2
12 1 0 1
13 1 2 1
6 1 3 3
10 3 1 1
4 0 1 2
4 2 2 3
5 0 3 3
13 3 1 3
6 3 1 1
4 2 1 2
4 0 3 3
9 3 2 2
13 2 1 2
13 2 1 2
6 1 2 1
10 1 3 0
4 0 0 1
13 0 0 2
2 2 2 2
9 3 2 1
13 1 2 1
6 1 0 0
10 0 3 3
4 1 1 0
4 2 0 1
10 0 2 0
13 0 3 0
6 3 0 3
13 3 0 0
2 0 2 0
13 3 0 2
2 2 3 2
8 1 2 0
13 0 1 0
13 0 2 0
6 0 3 3
10 3 2 1
13 2 0 2
2 2 2 2
13 2 0 0
2 0 1 0
13 1 0 3
2 3 2 3
10 0 2 2
13 2 3 2
6 2 1 1
10 1 2 2
4 0 3 3
4 2 1 0
13 2 0 1
2 1 3 1
1 0 3 0
13 0 1 0
6 0 2 2
10 2 1 1
4 3 0 2
4 1 2 0
4 2 0 3
12 0 3 0
13 0 3 0
6 0 1 1
10 1 1 2
4 1 1 1
4 3 3 0
12 1 3 0
13 0 1 0
6 0 2 2
10 2 3 3
4 3 0 1
4 0 3 2
4 2 2 0
3 1 2 1
13 1 1 1
6 1 3 3
10 3 2 2
4 2 0 3
4 0 1 1
5 0 3 1
13 1 1 1
6 2 1 2
10 2 3 3
4 3 1 1
13 3 0 2
2 2 0 2
7 0 1 2
13 2 2 2
6 2 3 3
4 3 1 2
0 0 2 2
13 2 3 2
6 3 2 3
10 3 1 0
4 0 2 1
4 3 0 3
4 0 0 2
3 3 2 1
13 1 1 1
13 1 1 1
6 1 0 0
10 0 1 2
4 0 1 1
4 1 0 3
13 3 0 0
2 0 2 0
2 3 1 1
13 1 3 1
13 1 2 1
6 1 2 2
10 2 0 3
4 3 0 2
13 0 0 1
2 1 2 1
4 0 1 0
8 1 2 1
13 1 2 1
6 1 3 3
10 3 2 2
4 2 3 0
4 3 1 1
4 0 1 3
7 0 1 3
13 3 2 3
6 3 2 2
10 2 0 3
4 3 3 0
4 3 0 2
3 1 2 1
13 1 3 1
6 3 1 3
10 3 3 0
4 1 2 3
4 3 3 1
13 3 0 2
2 2 2 2
7 2 1 2
13 2 1 2
13 2 1 2
6 0 2 0
10 0 1 3
4 0 1 1
4 1 3 0
4 1 1 2
2 0 1 0
13 0 1 0
6 0 3 3
10 3 1 0
4 2 2 2
4 3 1 1
4 0 1 3
9 3 2 2
13 2 1 2
6 0 2 0
10 0 0 1
4 2 2 0
13 2 0 3
2 3 1 3
4 2 1 2
14 0 3 3
13 3 3 3
6 3 1 1
4 2 0 3
4 3 3 0
15 0 3 0
13 0 1 0
6 1 0 1
10 1 3 2
13 3 0 0
2 0 2 0
4 1 2 1
1 0 3 0
13 0 2 0
6 2 0 2
10 2 3 0
4 0 3 3
4 3 3 1
13 2 0 2
2 2 2 2
9 3 2 3
13 3 1 3
13 3 1 3
6 3 0 0
10 0 0 3
4 2 0 1
4 0 1 2
4 3 1 0
0 2 0 0
13 0 1 0
13 0 1 0
6 3 0 3
10 3 3 1
4 2 2 3
13 2 0 0
2 0 3 0
0 2 0 2
13 2 1 2
13 2 3 2
6 2 1 1
10 1 2 3
4 0 2 2
4 2 0 1
3 0 2 2
13 2 3 2
6 2 3 3
4 0 0 1
4 1 2 0
4 0 3 2
6 0 0 0
13 0 2 0
13 0 1 0
6 0 3 3
4 1 2 0
4 3 0 1
4 2 0 2
10 0 2 0
13 0 3 0
6 3 0 3
10 3 3 0
4 2 2 1
4 2 1 3
4 0 2 2
11 2 3 3
13 3 1 3
6 0 3 0
10 0 0 1
4 2 2 2
4 0 1 3
4 1 1 0
9 3 2 3
13 3 2 3
6 3 1 1
10 1 1 3
13 3 0 1
2 1 2 1
4 0 3 2
13 0 2 1
13 1 1 1
13 1 1 1
6 3 1 3
10 3 0 1
4 3 1 0
4 3 3 2
4 0 1 3
11 3 2 2
13 2 3 2
6 1 2 1
10 1 3 0
13 3 0 2
2 2 2 2
4 0 1 1
4 3 1 3
13 3 1 3
6 0 3 0
10 0 3 1
4 0 0 0
4 3 2 2
4 0 1 3
11 3 2 0
13 0 3 0
6 0 1 1
10 1 0 2
13 3 0 3
2 3 2 3
4 2 3 0
4 3 0 1
1 0 3 3
13 3 1 3
6 3 2 2
10 2 0 1
4 3 2 2
13 0 0 3
2 3 2 3
4 3 0 0
15 0 3 0
13 0 1 0
13 0 2 0
6 0 1 1
4 2 2 2
4 0 0 3
4 3 0 0
9 3 2 2
13 2 3 2
13 2 2 2
6 2 1 1
10 1 3 2
4 2 2 3
13 3 0 1
2 1 1 1
4 1 0 0
12 0 3 1
13 1 1 1
13 1 3 1
6 1 2 2
10 2 3 1
4 3 0 0
4 0 1 3
4 2 2 2
9 3 2 3
13 3 3 3
6 3 1 1
10 1 3 0
13 1 0 1
2 1 3 1
4 2 3 3
4 0 3 2
11 2 3 3
13 3 2 3
6 0 3 0
10 0 1 3
4 2 0 1
4 2 3 2
4 1 1 0
6 0 0 2
13 2 2 2
13 2 3 2
6 2 3 3
10 3 1 0
4 1 3 3
4 3 0 2
4 3 1 1
4 2 1 2
13 2 2 2
6 2 0 0
10 0 2 3
4 0 2 0
4 3 1 2
4 2 0 1
8 1 2 2
13 2 2 2
6 2 3 3
10 3 1 1
13 0 0 0
2 0 2 0
13 0 0 3
2 3 1 3
4 3 3 2
14 0 3 3
13 3 1 3
13 3 2 3
6 1 3 1
10 1 1 3
4 0 1 0
4 1 3 1
4 0 1 2
13 1 2 0
13 0 3 0
6 0 3 3
10 3 2 2
13 2 0 0
2 0 2 0
4 2 3 3
5 0 3 3
13 3 1 3
6 2 3 2
10 2 2 1
4 1 2 3
4 3 3 0
4 0 1 2
13 3 2 2
13 2 3 2
6 1 2 1
10 1 1 3
13 3 0 0
2 0 1 0
4 2 3 2
4 2 0 1
10 0 2 2
13 2 1 2
13 2 1 2
6 2 3 3
10 3 0 1
4 0 3 0
4 0 0 3
4 1 3 2
4 3 2 3
13 3 3 3
6 3 1 1
10 1 2 2
4 2 0 3
4 2 0 0
4 2 1 1
5 0 3 1
13 1 2 1
6 1 2 2
10 2 3 1
4 1 2 3
4 2 1 2
14 0 3 0
13 0 1 0
6 0 1 1
10 1 3 3
4 3 0 2
13 0 0 0
2 0 2 0
13 3 0 1
2 1 1 1
0 0 2 1
13 1 3 1
6 3 1 3
10 3 2 0
4 0 1 1
4 3 0 3
4 0 3 2
4 2 3 1
13 1 2 1
6 0 1 0
10 0 3 2
4 3 1 1
4 1 3 0
4 2 1 3
12 0 3 1
13 1 1 1
6 2 1 2
4 3 2 1
4 2 0 0
4 0 0 3
1 0 3 1
13 1 3 1
6 2 1 2
10 2 1 1
4 3 3 0
4 0 0 2
0 2 0 3
13 3 2 3
6 3 1 1
10 1 0 0
4 0 0 3
4 2 0 1
13 0 0 2
2 2 3 2
8 1 2 3
13 3 3 3
6 0 3 0
10 0 0 2
4 1 1 1
4 2 3 0
4 2 0 3
5 0 3 1
13 1 1 1
13 1 3 1
6 2 1 2
10 2 1 0
4 1 1 1
4 0 1 3
4 2 0 2
9 3 2 3
13 3 1 3
6 0 3 0
10 0 3 1
13 2 0 0
2 0 2 0
4 3 1 3
15 3 0 0
13 0 3 0
13 0 1 0
6 1 0 1
10 1 1 0
13 1 0 1
2 1 1 1
13 3 0 3
2 3 2 3
1 2 3 3
13 3 2 3
6 0 3 0
10 0 1 2
4 2 1 0
4 0 2 1
4 2 1 3
5 0 3 0
13 0 3 0
6 0 2 2
10 2 0 3
13 0 0 0
2 0 2 0
4 3 2 2
4 1 3 1
13 1 2 2
13 2 2 2
6 2 3 3
10 3 0 1
13 0 0 3
2 3 3 3
4 3 1 0
4 0 2 2
0 2 0 3
13 3 1 3
6 1 3 1
10 1 0 0
4 3 2 2
4 0 3 3
4 2 0 1
11 3 2 1
13 1 3 1
6 0 1 0
4 1 3 1
4 1 1 3
13 3 2 3
13 3 3 3
13 3 2 3
6 0 3 0
10 0 2 1
4 0 0 3
4 0 2 0
11 3 2 2
13 2 1 2
6 2 1 1
4 2 2 0
4 3 1 2
4 2 2 3
5 0 3 3
13 3 2 3
13 3 3 3
6 3 1 1
10 1 2 0
4 0 2 3
13 0 0 1
2 1 2 1
8 1 2 1
13 1 3 1
6 0 1 0
4 0 0 1
4 2 3 2
1 2 3 1
13 1 1 1
13 1 3 1
6 1 0 0
10 0 2 1
13 1 0 0
2 0 0 0
4 0 1 2
13 0 0 3
2 3 2 3
11 2 3 2
13 2 2 2
13 2 1 2
6 2 1 1
13 1 0 0
2 0 2 0
4 0 3 3
4 2 2 2
1 2 3 0
13 0 3 0
6 0 1 1
10 1 3 0
4 2 0 1
4 3 1 2
1 1 3 2
13 2 1 2
6 2 0 0
10 0 3 2
4 2 2 0
4 1 0 1
13 3 0 3
2 3 2 3
12 1 0 0
13 0 1 0
6 2 0 2
4 2 1 0
5 0 3 0
13 0 2 0
6 0 2 2
10 2 3 1
13 2 0 0
2 0 3 0
4 0 2 3
4 2 1 2
8 2 0 3
13 3 1 3
6 1 3 1
10 1 1 2
4 2 2 0
13 2 0 1
2 1 3 1
4 2 3 3
7 0 1 0
13 0 2 0
6 2 0 2
10 2 2 1
4 0 1 3
4 0 2 0
4 2 3 2
9 3 2 3
13 3 2 3
6 1 3 1
4 1 0 0
4 3 2 3
10 0 2 2
13 2 1 2
6 1 2 1
10 1 0 2
4 3 1 1
4 2 2 0
4 0 1 3
7 0 1 0
13 0 2 0
13 0 3 0
6 2 0 2
10 2 3 3
4 2 2 0
13 3 0 1
2 1 1 1
4 0 0 2
13 1 2 2
13 2 2 2
13 2 1 2
6 2 3 3
4 0 3 2
4 3 2 0
0 2 0 1
13 1 1 1
6 3 1 3
10 3 2 1
13 0 0 2
2 2 3 2
4 1 2 3
4 2 1 0
0 0 2 2
13 2 1 2
13 2 2 2
6 2 1 1
10 1 2 2
4 3 0 1
13 2 0 3
2 3 2 3
7 0 1 1
13 1 1 1
13 1 1 1
6 2 1 2
10 2 3 3
4 3 3 1
4 1 1 0
4 2 0 2
7 2 1 2
13 2 3 2
6 3 2 3
4 2 2 1
4 3 1 0
4 0 0 2
3 0 2 1
13 1 3 1
6 1 3 3
10 3 1 0
4 2 0 1
4 2 3 2
13 3 0 3
2 3 0 3
1 1 3 1
13 1 2 1
6 0 1 0
10 0 0 1
4 1 1 2
13 3 0 3
2 3 3 3
4 2 3 0
15 3 0 0
13 0 1 0
13 0 3 0
6 0 1 1
4 1 0 0
4 1 2 3
13 0 0 2
2 2 2 2
10 0 2 3
13 3 3 3
13 3 3 3
6 3 1 1
4 3 0 0
13 1 0 3
2 3 2 3
7 2 0 0
13 0 2 0
13 0 3 0
6 0 1 1
13 2 0 0
2 0 0 0
13 2 0 3
2 3 1 3
4 3 0 2
13 3 2 0
13 0 3 0
6 1 0 1
10 1 1 0
4 0 0 2
4 1 3 1
13 1 2 2
13 2 2 2
6 2 0 0
4 1 1 2
4 3 0 1
4 2 0 3
15 1 3 1
13 1 1 1
13 1 3 1
6 1 0 0
13 2 0 2
2 2 2 2
4 0 3 3
4 0 3 1
9 3 2 2
13 2 3 2
6 2 0 0
4 2 0 2
4 2 0 1
9 3 2 3
13 3 3 3
13 3 3 3
6 3 0 0
10 0 0 1
4 2 1 0
4 1 3 2
4 2 1 3
5 0 3 2
13 2 2 2
13 2 1 2
6 2 1 1
4 0 0 0
13 0 0 2
2 2 0 2
13 1 0 3
2 3 1 3
6 3 3 0
13 0 2 0
13 0 1 0
6 0 1 1
4 1 2 0
4 2 1 3
6 0 0 2
13 2 1 2
13 2 1 2
6 2 1 1
10 1 1 2
4 1 2 3
4 0 2 1
4 2 0 0
14 0 3 1
13 1 2 1
13 1 2 1
6 2 1 2
10 2 2 0
4 1 2 2
4 3 2 3
4 3 0 1
3 1 2 2
13 2 1 2
13 2 2 2
6 2 0 0
10 0 1 3
4 3 3 0
4 2 1 2
4 2 3 1
7 2 0 2
13 2 3 2
6 3 2 3
10 3 3 1
4 2 2 0
4 2 3 3
4 3 2 2
5 0 3 2
13 2 1 2
13 2 2 2
6 1 2 1
4 1 2 0
13 3 0 3
2 3 0 3
4 3 2 2
11 3 2 0
13 0 3 0
13 0 2 0
6 0 1 1
4 0 0 2
4 1 1 0
4 3 2 3
3 3 2 3
13 3 2 3
6 1 3 1
4 2 3 3
4 2 0 0
11 2 3 0
13 0 2 0
6 0 1 1
10 1 3 3
4 1 1 0
13 3 0 1
2 1 0 1
2 0 1 0
13 0 3 0
6 0 3 3
10 3 2 2
13 1 0 0
2 0 2 0
4 3 3 1
4 1 0 3
14 0 3 0
13 0 2 0
6 2 0 2
4 1 3 0
4 2 0 3
4 2 2 1
12 0 3 3
13 3 3 3
6 2 3 2
10 2 2 1
4 3 3 2
13 0 0 3
2 3 1 3
6 3 3 0
13 0 1 0
6 0 1 1
10 1 0 3
4 1 0 0
4 0 2 1
4 2 1 2
10 0 2 1
13 1 2 1
6 3 1 3
10 3 3 0
4 0 2 1
4 3 3 2
4 0 1 3
11 3 2 3
13 3 3 3
13 3 2 3
6 3 0 0
4 0 0 2
4 3 3 1
13 1 0 3
2 3 2 3
11 2 3 2
13 2 3 2
6 0 2 0
10 0 3 3
4 0 0 2
4 1 0 1
4 1 0 0
13 1 2 2
13 2 2 2
6 3 2 3
10 3 2 2
4 0 0 1
4 0 2 3
2 0 1 1
13 1 3 1
13 1 1 1
6 2 1 2
10 2 3 0
4 3 0 1
4 1 1 3
4 0 3 2
2 3 1 3
13 3 2 3
13 3 1 3
6 0 3 0
10 0 1 1
4 2 3 2
4 0 3 3
4 1 1 0
9 3 2 2
13 2 3 2
6 1 2 1
4 2 3 3
4 2 2 0
13 2 0 2
2 2 1 2
5 0 3 0
13 0 3 0
6 0 1 1
4 0 2 2
4 3 0 0
11 2 3 3
13 3 2 3
13 3 3 3
6 1 3 1
10 1 0 0
4 0 3 3
13 1 0 1
2 1 3 1
4 2 3 2
7 2 1 3
13 3 2 3
6 0 3 0
instructions