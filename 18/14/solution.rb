
class HotChocolate
  def initialize
    @elf1 = 0
    @elf2 = 1
    @recipes = [3, 7]
  end

  def last_ten_after(n)
    until @recipes.length > n + 9
      generate
    end

    @recipes[n..(n + 9)].join
  end

  def first_appearance_of(sequence)
    sequence = sequence.chars.map(&:to_i)
    @i = 0
    until appears?(sequence)
      p @i if (@i += 1) % 100_000 == 0
      generate
    end

    appears?(sequence)
  end

  def appears?(sequence)
    # Only have to check the last two generated numbers because
    # that's all we make until we check again in the loop inside
    # `first_appearance_of`.
    return @recipes.length - sequence.length if contains_at(-sequence.length, sequence)
    return @recipes.length - sequence.length - 1 if contains_at(-sequence.length - 1, sequence)

    nil
  end

  def contains_at(start, sequence)
    return false if @recipes.length < sequence.length + start - 1

    for i in 0..sequence.length - 1
      return false if @recipes[start + i] != sequence[i]
    end

    true
  end

  def generate
    sum_of_digits.each { |digit| @recipes << digit }

    @elf1 += elf1 + 1
    @elf1 %= @recipes.length

    @elf2 += elf2 + 1
    @elf2 %= @recipes.length
  end

  def show
    puts @recipes.each_with_index.map { |recipe, idx|
      if idx == @elf1
        "(#{recipe})"
      elsif idx == @elf2
        "[#{recipe}]"
      else
        " #{recipe} "
      end
    }.join
  end

  def sum_of_digits
    (elf1 + elf2).to_s.chars.map(&:to_i)
  end

  def elf1
    @recipes[@elf1]
  end

  def elf2
    @recipes[@elf2]
  end
end