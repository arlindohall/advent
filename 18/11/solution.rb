
FuelCell = Struct.new(:x, :y, :serial)

class FuelCell
  def power_level
    hundreds_digit - 5
  end

  def hundreds_digit
    product_serial_rack % 1000 / 100
  end

  def product_serial_rack
    increase_by_serial * rack_id
  end

  def increase_by_serial
    serial + product_rack_y 
  end

  def product_rack_y
    rack_id * y
  end

  def rack_id
    x + 10
  end
end

class FuelGrid
  def initialize(serial)
    @serial = serial
  end

  def solve
    [best_square, best_any_size]
  end

  def best_square
    coordinates(1, 1, 298).max_by{ |x, y| square_power_level(x, y) }
  end

  def best_any_size
    # Arbitrarily assume it won't be bigger than 16x16 because the sum
    # of the cells approaches zero as N -> inf, turned out to be right
    # I aslo checked 16-20 and 16 held which gave me some confidence
    12.upto(16).flat_map { |n| coordinates(1, 1, (300 - n) + 1).map { |x, y| [x, y, n] } }
      .max_by { |args| square_power_level(*args) }
  end

  def cells
    @cells ||= generate_cells
  end

  def generate_cells
    coordinates.map { |x, y| [[x, y], FuelCell.new(x, y, @serial).power_level] }
      .to_h
  end

  def coordinates(x = 1, y = 1, n = 300)
    x.upto(x + n - 1).flat_map { |x| y.upto(y + n - 1).map { |y| [x, y] } }
  end

  def square_power_level(x, y, size = 3)
    coordinates(x, y, size)
      .map { |x, y| cells[[x, y]] }
      .sum
  end
end

@example_cells = {
  FuelCell.new(3, 5, 8) => 4,
  FuelCell.new(122, 79, 57) => -5,
  FuelCell.new(217, 196, 39) => 0,
  FuelCell.new(101, 153, 71) => 4,
}
def example_cells
  raise unless @example_cells.map { |f, pl| f.power_level == pl }.all?
end

@example_grid = {
  FuelGrid.new(18) => [[33, 45], 29],
  FuelGrid.new(42) => [[21, 61], 30],
}
def example_grid
  raise unless @example_grid.map { |g, v| g.best_square == v.first }.all?
  raise unless @example_grid.map { |g, v| g.square_power_level(*v.first) == v.last }.all?
end

@example_full = {
  FuelGrid.new(18) => [[90, 269, 16], 113],
  FuelGrid.new(42) => [[232, 251, 12], 119],
}
def example_full
  raise unless @example_full.map { |g, v| g.best_any_size == v.first }.all?
  raise unless @example_full.map { |g, v| g.square_power_level(*v.first) == v.last }.all?
end