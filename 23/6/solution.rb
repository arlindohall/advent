def solve(input = read_input) =
  BoatRaces.new(input).then { |br| [br.ways_to_win, br.ways_to_win_spaceless] }

class BoatRaces
  def initialize(text)
    @text = text
  end

  def ways_to_win
    races.map(&:winning_times).product
  end

  def ways_to_win_spaceless
    spaceless.winning_times
  end

  def races
    times.zip(distances).map { |t, d| Race.new(t, d) }
  end

  def spaceless
    Race.new(
      @text.lines.first.split.drop(1).join.to_i,
      @text.lines.second.split.drop(1).join.to_i
    )
  end

  def times
    @text.lines.first.split.drop(1).map(&:to_i)
  end

  def distances
    @text.lines.second.split.drop(1).map(&:to_i)
  end
end

class Race
  def initialize(time, distance)
    @time = time
    @distance = distance
  end

  def range
    WinningTimes.new(@time, @distance).range
  end

  def winning_times
    range.size
  end
end

<<-DOC
distance = speed * time_left
time_left = time - charge_time
speed = charge_time

distance = charge_time * (time - charge_time)
distance = charge_time * time - charge_time^2 = ct - c^2

distance > high_score
ct - c^2 > high_score : find c
c^2 - ct + high_score < 0
c^2 - ct + high_score = 0
c = (t +- sqrt(t^2 - 4*high_score)) / 2

min_winning_time = ceil ( 1/2 ( t - sqrt(t^2 - 4*high_score) ) )
max_winning_time = floor ( 1/2 ( t + sqrt(t^2 - 4*high_score) ) )
DOC
class WinningTimes
  def initialize(time, high_score)
    @time = time
    @high_score = high_score
  end

  def range
    min_winning_time..max_winning_time
  end

  def min_winning_time
    ceil(0.5 * (@time - square_root_term))
  end

  def max_winning_time
    floor(0.5 * (@time + square_root_term))
  end

  def square_root_term
    Math.sqrt(@time**2 - 4 * @high_score)
  end

  def ceil(number)
    number.ceil == number ? number.ceil + 1 : number.ceil
  end

  def floor(number)
    number.floor == number ? number.floor - 1 : number.floor
  end
end
