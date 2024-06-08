def solve(input = read_input) =
  PulseModules.then { |cl| [cl.new(input).part1, cl.new(input).part2] }

class PulseModules
  Pulse = Struct.new(:source, :value, :dest)

  def initialize(text)
    @text = text
    @low_pulses = 0
    @high_pulses = 0
    @presses = 0
    @sq_input_periods = {}
  end

  memoize def modules
    @text
      .split("\n")
      .map do |line|
        if line.start_with?("broadcaster")
          [
            :broadcaster,
            [nil, line.split(" -> ").second.split(", ").map(&:to_sym)]
          ]
        else
          type = line[0]
          name = line[1..].split(" -> ").first
          dest = line.split(" -> ").second.split(", ")
          [name.to_sym, [type, dest.map(&:to_sym)]]
        end
      end
      .to_h
  end

  def part1
    1000.times { push_button }
    @low_pulses * @high_pulses
  end

  def part2
    # :sq only input to :rx, and it's a conjunction
    # :rx shows `low` when all :sq inputs are `high`
    sq_inputs =
      modules.select { |name, (type, dests)| dests.include?(:sq) }.keys
    @sq_input_periods = sq_inputs.map { |name| [name, nil] }.to_h

    raise "Impossible to solve if no :sq" if @sq_input_periods.empty?

    loop do
      push_button
      if @sq_input_periods.values.all?
        return @sq_input_periods.values.reduce(&:lcm)
      end
    end
  end

  def push_button
    @presses += 1
    @pulses = []
    send_pulse(:button, :low, :broadcaster)

    until @pulses.empty?
      from, type, to = @pulses.shift
      send_pulse(from, type, to)
    end
  end

  def flip_flops(to, value = nil)
    @flip_flops ||= {}
    @flip_flops[to] = :off if @flip_flops[to].nil?
    @flip_flops[to] = value if value
    @flip_flops[to]
  end

  def conjunctions(name)
    @conjunctions ||= {}
    @conjunctions[name] ||= modules
      .filter_map do |mod_name, (type, dests)|
        next unless dests.include?(name)
        [mod_name, :low]
      end
      .to_h
    @conjunctions[name]
  end

  def send_pulse(from, sig_type, to)
    # puts "#{from} -#{sig_type}-> #{to}"
    @low_pulses += 1 if sig_type == :low
    @high_pulses += 1 if sig_type == :high

    module_type, dests = modules[to]
    return if dests.nil?

    @sq_input_periods[from] = @presses if to == :sq && sig_type == :high

    case module_type
    when "%" # FlipFlop
      if sig_type == :low
        if flip_flops(to) == :off
          flip_flops(to, :on)
          dests.each { |dest| @pulses << [to, :high, dest] }
        else
          flip_flops(to, :off)
          dests.each { |dest| @pulses << [to, :low, dest] }
        end
      end
    when "&" # Conjunction
      conjunctions(to)[from] = sig_type
      result = conjunctions(to).values.all? { |v| v == :high } ? :low : :high
      dests.each { |dest| @pulses << [to, result, dest] }
    when nil # Broadcaster
      dests.each { |dest| @pulses << [to, sig_type, dest] }
    else
      raise "Impossible module type #{module_type}"
    end
  end
end
