def solve
  Handshake.new(read_input).encryption_key
end

class Handshake < Struct.new(:input)
  def entities
    @entities ||= input.split.map(&:to_i).map { Entity.new(_1) }
  end

  def encryption_key
    entities.first.loop_size.times { entities.second.transform }

    entities.second.value
  end

  class Entity < Struct.new(:subject_number)
    attr_reader :value

    def transform
      @value ||= subject_number
      @value = (value * subject_number) % 20_201_227
    end

    def loop_size
      checker = Entity.new(7)
      i = 0

      until checker.value == subject_number
        checker.transform
        i += 1
      end

      i
    end
  end
end
