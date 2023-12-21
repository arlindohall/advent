def solve(input = read_input) =
  LensInitialization.new(input).then { |li| [li.hash_sum, li.focusing_power] }

class LensInitialization
  def initialize(text)
    @text = text
  end

  def hash_sum
    sequence.map { |step| step.hash_value }.sum
  end

  def focusing_power
    lens_array.configure.focusing_power
  end

  def sequence
    @text.split(",").map { |step| Step.new(step) }
  end

  def instructions
    sequence.map { |step| step.instruction }
  end

  def lens_array
    LensArray.new(instructions)
  end
end

class LensArray
  def initialize(instructions, boxes = [])
    @instructions = instructions
    @boxes = boxes
  end

  def configure
    @instructions.empty? ? self : configure_step.configure
  end

  def configure_step
    inst = @instructions.first

    LensArray.new(@instructions.drop(1), inst.call(@boxes))
  end

  def focusing_power
    @boxes
      .each_with_index
      .map { |box, index| box.nil? ? 0 : box.focusing_power(index) }
      .sum
  end
end

class Step
  def initialize(text)
    @text = text
  end

  def hash_value
    HashAlgorithm.call(@text)
  end

  def instruction
    @text.match(/-/) ? remove : insert
  end

  def remove
    Remove.new(
      HashAlgorithm.call(@text.split("-").first),
      @text.split("-").first
    )
  end

  def insert
    Insert.new(
      HashAlgorithm.call(@text.split("=").first),
      @text.split("=").first,
      @text.split("=").last.to_i
    )
  end
end

class HashAlgorithm
  def self.call(text)
    new(text).call
  end

  def initialize(text)
    @text = text
  end

  def call
    @current_value = 0
    @text.each_char { |char| hash_step(char) }
    @current_value
  end

  def hash_step(char)
    @current_value += char.ord
    @current_value *= 17
    @current_value %= 256
  end
end

class Remove < Struct.new(:box_number, :label)
  def call(boxes)
    boxes = boxes.dup
    boxes[box_number] ||= Box.new
    boxes[box_number].remove(label)

    boxes
  end
end

class Insert < Struct.new(:box_number, :label, :focal_length)
  def call(boxes)
    boxes = boxes.dup
    boxes[box_number] ||= Box.new
    boxes[box_number].insert(label, focal_length)

    boxes
  end
end

class Box
  class Lens < Struct.new(:label, :focal_length)
  end

  def initialize
    @lenses = []
  end

  def remove(label)
    # raise "No such label: #{label}" unless has_label?(label)

    @lenses.delete_if { |lens| lens.label == label }
  end

  def insert(label, focal_length)
    if has_label?(label)
      @lenses.find { |lens| lens.label == label }.focal_length = focal_length
    else
      @lenses << Lens.new(label, focal_length)
    end
  end

  def focusing_power(index)
    @lenses
      .each_with_index
      .map do |lens, lens_index|
        lens.focal_length * (index + 1) * (lens_index + 1)
      end
      .sum
  end

  def has_label?(label)
    count = @lenses.count { |lens| lens.label == label }
    raise "Multiple labels: #{label}" if count > 1

    count == 1
  end
end
