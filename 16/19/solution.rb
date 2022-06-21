
class Elephant
  def initialize(size)
    @size = size
    @elves = 1.upto(size).to_a
    @index = 0
    @removed = 0
  end

  def play
    until @removed == @size-1
      remove_next
    end
    @elves[@index]
  end

  def remove_next
    increment
    delete_one
    increment
  end

  def increment
    @index = ((@index + 1) % @size)
    while @elves[@index].nil?
      @index = ((@index + 1) % @size)
    end
  end

  def delete_one
    @removed += 1
    @elves[@index] = nil
  end
end

@example = Elephant.new(5)
@input = Elephant.new(3018458)