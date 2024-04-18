$_debug = false

class Trench
  RIGHT = [1, 0]
  UP = [0, -1]
  LEFT = [-1, 0]
  DOWN = [0, 1]

  def initialize(text)
    @text = text
  end

  def instructions
    @text.split("\n").map { |it| Instruction.parse(it) }
  end

  def hex_instructions
    @text.split("\n").map { |it| Instruction.parse_hex(it) }
  end

  def part1
    discrete_integral(instructions)
  end

  def part2
    discrete_integral(hex_instructions)
  end

  def discrete_integral(instructions)
    area, x, y = 0, 0, 0

    instructions.each do |ins|
      dx, dy = ins.direction
      distance = ins.distance

      area += distance if dx.positive?
      area += distance * (x + 1) if dy.positive?
      area -= distance * x if dy.negative?

      x += dx * distance
      y += dy * distance

      _debug({ x:, y:, dx:, dy:, distance:, area: })
    end

    area + 1
  end

  Instruction =
    Struct.new(:direction_letter, :distance) do
      def self.parse(line)
        direction_letter, distance, _hex_part = line.split

        Instruction[direction_letter, distance.to_i]
      end

      def self.parse_hex(line)
        _direction_letter, _distance, hex_part = line.split
        hex = hex_part[2..7]

        Instruction[hex[-1], hex[...-1].to_i(16)]
      end

      def direction
        case direction_letter
        when "R", "0"
          RIGHT
        when "D", "1"
          DOWN
        when "L", "2"
          LEFT
        when "U", "3"
          UP
        else
          raise "Unknown direction: #{direction_letter}"
        end
      end
    end
end
