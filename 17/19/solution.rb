
require 'pathname'

class Diagram
  attr_reader :grid
  def initialize(grid)
    @grid = grid
  end

  def self.of(string)
    new(string.split("\n").map(&:chars))
  end

  def path
    @letters, @direction, = [], :down
    @location = starting_point

    @steps = 0
    while next_location
      follow(next_location)
      record
    end

    [@letters.join, @steps]
  end

  def next_location
    direction = @direction
    case current
    when '|', '-'
      # do nothing
    when '+'
      direction = turn
    when /\w/
      # skip
    when ' '
      return
    else
      raise "Unknown character: #{current}, location=#{@location}"
    end

    p [current, @location, direction, continue(direction)]
    [direction, continue(direction)]
  end

  def valid?(direction, location)
    x, y = location
    case direction
    when :up, :down
      pipe?(x, y) || word?(x, y) || intersection?(x, y)
    when :left, :right
      dash?(x, y) || word?(x, y) || intersection?(x, y)
    end
  end

  def pipe?(x, y)
    @grid[x][y] == '|'
  end

  def dash?(x, y)
    @grid[x][y] == '-'
  end

  def word?(x, y)
    /\w/.match(@grid[x][y])
  end

  def intersection?(x, y)
    @grid[x][y] == '+'
  end

  def follow(change)
    @steps += 1
    @direction, @location = change
  end

  def record
    if /\w/.match(current)
      @letters << current
    end
  end

  def turn
    possible_direcitons = [:up, :down, :left, :right]
      .filter{|d| in_bounds?(d) }
      .filter{|d| valid?(d, move_after(d))}
      .filter{|d| !coming_from?(d)}

    if possible_direcitons.size != 1
      raise "Found #{possible_direcitons.size} possible directions, but expected 1: location=#{@location}"
    end

    possible_direcitons.first
  end

  def coming_from?(direction)
    case @direction
    when :up
      direction == :down
    when :down
      direction == :up
    when :left
      direction == :right
    when :right
      direction == :left
    end
  end

  def in_bounds?(direction)
    x, y = @location
    case direction
    when :up
      x > 0
    when :down
      x < @grid.size-1
    when :left
      y > 0
    when :right
      y < @grid.first.size-1
    end
  end

  def move_after(direction)
    x, y = @location
    case direction
    when :down
      [x + 1, y]
    when :up
      [x - 1, y]
    when :right
      [x, y + 1]
    when :left
      [x, y - 1]
    else
      raise "Invalid direction: #{direction}"
    end
  end

  def continue(direction)
    move_after(direction)
  end

  def current
    x, y = @location
    @grid[x][y]
  end

  # x is vertical/rows/first dimension, y is horizontal/columns/second dimension
  def starting_point
    [0, @grid.first.index('|')]
  end
end

@example = File.read(Pathname.new(__FILE__).parent.join("example.txt"))
@input = File.read(Pathname.new(__FILE__).parent.join("input.txt"))