def solve(input = read_input) =
  CubeConundrum.new(input).then { |it| [it.possible_ids, it.powers] }

class CubeConundrum
  def initialize(input)
    @input = input
  end

  def possible_ids
    possible.map(&:id).sum
  end

  def powers
    games.map(&:power).sum
  end

  def possible
    games.filter { |g| g.possible_with(Bag.new(red: 12, green: 13, blue: 14)) }
  end

  def games
    @input.split("\n").map { |l| Game.new(l) }
  end
end

class Game
  def initialize(line)
    @line = line
  end

  def id
    @line.match(/Game (\d+)/)[1].to_i
  end

  def sets
    @line.split(": ").second.split("; ").map { |s| CubeSet.new(s) }
  end

  def possible_with(bag)
    sets.all? { |s| s.possible_with(bag) }
  end

  def power
    max(:red) * max(:green) * max(:blue)
  end

  def max(color)
    sets.map { |it| it.send(color) }.max
  end
end

class CubeSet
  def initialize(text)
    @text = text
  end

  def possible_with(bag)
    red <= bag.red && green <= bag.green && blue <= bag.blue
  end

  def red
    return 0 unless (match = @text.match(/(\d+) red/))

    match[1].to_i
  end

  def green
    return 0 unless (match = @text.match(/(\d+) green/))

    match[1].to_i
  end

  def blue
    return 0 unless (match = @text.match(/(\d+) blue/))

    match[1].to_i
  end
end

class Bag
  def initialize(**cubes)
    @cubes = cubes
  end

  def red = @cubes[:red]
  def green = @cubes[:green]
  def blue = @cubes[:blue]
end
