class Trench
  RIGHT = [1, 0]
  UP = [0, -1]
  LEFT = [-1, 0]
  DOWN = [0, 1]

  def initialize(text)
    @text = text
  end

  memoize def instructions
    @text.split("\n").map { |it| Instruction.parse(it) }
  end

  def part1
    fill = Set.new
    x, y = [0, 0]

    instructions.each do |ins|
      ins.distance.times do
        x += ins.direction_vector[0]
        y += ins.direction_vector[1]
        fill << [x, y]
      end
    end

    fill_step = Set[[1, 1]]
    until fill_step.empty?
      fill += fill_step
      next_fill_step = Set.new
      fill_step
        .flat_map { |x, y| [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]] }
        .reject { |x, y| fill.include?([x, y]) }
        .each { |x, y| next_fill_step << [x, y] }
      fill_step = next_fill_step
    end

    fill.size
  end

  # Define area as the sum of the squares to the left of x greater than 0
  # when heading down, minus the sum of the squares to the right greater than 0
  # when heading up. If x less than zero, area is positive going up and negative
  # going down. If we carve out sections then we'll double count and cancel
  # them out. I think there's some calculus to prove this about a loop interval
  # or something but I literally couldn't remember.
  def part2
    area = 0
    x, y = [0, 0]

    instructions.each do |ins|
      dx, dy = ins.hex_direction

      area += dx.abs unless dy.zero?

      if x >= 0 && dx == 0
        area += dy * ins.hex_distance * (x + 1)
      elsif x < 0 && dx == 0
        area += dy * ins.hex_distance * (x.abs + 1)
      end

      x += dx * ins.hex_distance
      y += dy * ins.hex_distance
    end

    area
  end

  Instruction =
    Struct.new(:direction, :distance, :hex) do
      def self.parse(line)
        direction, distance, hex_part = line.split
        hex = hex_part[2..7]

        Instruction[direction, distance.to_i, hex]
      end

      def direction_vector
        case direction
        when "R"
          RIGHT
        when "U"
          UP
        when "L"
          LEFT
        when "D"
          DOWN
        else
          raise "Unknown direction: #{direction}"
        end
      end

      def hex_distance
        hex[...-1].to_i(16)
      end

      def hex_direction
        case hex[-1]
        when "0"
          RIGHT
        when "1"
          DOWN
        when "2"
          LEFT
        when "3"
          UP
        end
      end
    end
end
