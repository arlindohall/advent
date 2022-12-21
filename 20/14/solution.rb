
class DockingProgram < Struct.new(:text)
  attr_reader :mask
  def instructions
    text.strip.split("\n").map { |line| Command.new(line) }
  end

  def memory
    @memory ||= {}
  end

  def sum_memory
    instructions.each do |inst|
      @mask = inst if inst.mask?
      memory[inst.address] = mask.apply_mask(inst.value) if inst.mem?
    end

    memory.values.sum
  end

  def sum_memory_v2
    puts "Runnig #{instructions.size} instructions"
    instructions.each_with_index do |inst, idx|
      puts "#{idx}/#{inst.text}"
      @mask = inst if inst.mask?
      mask.apply_mem(inst) { |ad| memory[ad] = inst.value } if inst.mem?
    end

    memory.values.sum
  end
end

class Command < Struct.new(:text)
  def mem?
    text.start_with?("mem")
  end

  def mask?
    text.start_with?("mask")
  end

  def address
    text.split("[").last.split("]").first.to_i
  end

  def address_binary
    address.to_s(2).rjust(36, "0")
  end

  def value
    text.split(" = ").last.to_i
  end

  def apply_mask(value)
    address_binary
      .chars.reverse
      .each_with_index.map { |ch, idx| mask[idx] || ch }
      .reverse.join
      .to_i(2)
  end

  def apply_mem(inst)
    if no_subs?
      yield(apply_one_mem(inst))
      return
    end

    first_substitute
      .each { |subst| subst.apply_mem(inst) { |ad| yield(ad) } }
  end

  def apply_one_mem(inst)
    inst.address_binary.chars.reverse.each_with_index.map do |ch, idx|
      case mask[idx]
      when "0"
        ch
      when "1"
        "1"
      when "F"
        "0"
      else
        raise "Failure because mask not simplified #{text}/#{idx}"
      end
    end.reverse.join.to_i(2)
  end

  def first_substitute
    @first_substitute ||= [
      Command.new(text.sub("X", "F")), # force zero
      Command.new(text.sub("X", "1")),
    ]
  end

  def no_subs?
    text.exclude?("X")
  end

  def mask
    mask_text.chars.reverse.each_with_index.filter do |char, index|
      char != "X"
    end.map do |char, index|
      [index, char]
    end.to_h
  end

  def mask_text
    text.split(" = ").last
  end
end