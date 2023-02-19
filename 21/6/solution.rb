# Dup shares the initial state but it is replaced not modified by #day!
def solve =
  LanternfishPopulation
    .parse(read_input)
    .then { |lp| [lp.dup.after_days(80), lp.dup.after_days(256)] }

class LanternfishPopulation
  attr_reader :fish
  def initialize(fish)
    @fish = fish
  end

  def after_days(days = 80)
    days.times { day! }
    fish.values.sum
  end

  def day!
    @fish = update_fish
  end

  def update_fish
    decreased_fish.merge(spawned_fish)
  end

  def spawned_fish
    { 6 => (fish[0] || 0) + (fish[7] || 0), 8 => (fish[0] || 0) }
  end

  def decreased_fish
    1.upto(8).map { |days| [days - 1, fish[days] || 0] }.to_h
  end

  def self.parse(text)
    new(text.split(",").map(&:to_i).count_values)
  end
end
