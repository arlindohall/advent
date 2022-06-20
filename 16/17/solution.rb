
require 'digest'

class Path
  attr_reader :steps, :location

  def initialize(steps, location, passcode)
    @grid_rows, @grid_cols = 4, 4
    @steps = steps.freeze
    @location = location
    @passcode = passcode
  end

  def open_doors
    ['U','D','L','R'].filter do |direction|
      !at_edge?(direction)
    end.filter do |direction|
      doors[direction]
    end
  end

  def at_edge?(direction)
    case direction
    when 'U'
      @location.first == 0
    when 'D'
      @location.first == @grid_rows-1
    when 'L'
      @location.last == 0
    when 'R'
      @location.last == @grid_cols-1
    end
  end

  def doors
    @doors ||= begin
      up, down, left, right = hash.chars
      {
        'U' => open?(up),
        'D' => open?(down),
        'L' => open?(left),
        'R' => open?(right),
      }
    end
  end

  def hash
    Digest::MD5.hexdigest("#{@passcode}#{@steps.join}")
  end

  def open?(character)
    case character
    when 'b', 'c', 'd', 'e', 'f'
      true
    else
      false
    end
  end

  def solved?
    @location.first == @grid_rows-1 &&
      @location.last == @grid_cols-1
  end
end

class Solver
  def initialize(passcode)
    @passcode = passcode
  end

  def solve
    @paths = [Path.new([], [0, 0], @passcode)]

    until @paths.empty?
      path = @paths.shift
      return path if path.solved?
      path.open_doors.map do |door|
        Path.new(path.steps + [door], update(path.location, door), @passcode)
      end.each do |path|
        p path
        @paths << path
      end
    end
  end

  def update(location, door)
    case door
    when 'U'
      [location.first-1, location.last]
    when 'D'
      [location.first+1, location.last]
    when 'L'
      [location.first, location.last-1]
    when 'R'
      [location.first, location.last+1]
    end
  end
end