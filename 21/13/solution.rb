def solve =
  [
    Paper.parse(read_input).fold.dots.size,
    Paper.parse(read_input).fold_completely.debug
  ]

class Paper
  attr_reader :dots, :folds
  def initialize(dots, folds)
    @dots = dots
    @folds = folds
  end

  def fold
    Paper.new(next_fold, folds.drop(1))
  end

  def fold_completely
    f = self
    f = f.fold until f.folds.empty?

    f
  end

  def next_fold
    f = folds.first
    case f.direction
    when :vertical
      dots.map { |x, y| [f.axis - (x - f.axis).abs, y] }.to_set
    when :horizontal
      dots.map { |x, y| [x, f.axis - (y - f.axis).abs] }.to_set
    end
  end

  def debug
    xmin, xmax = dots.map(&:first).minmax
    ymin, ymax = dots.map(&:second).minmax
    ymin
      .upto(ymax)
      .map do |y|
        xmin
          .upto(xmax)
          .map { |x| dots.include?([x, y]) ? "#" : "." }
          .join
          .darken_squares
      end
      .join("\n")
  end

  def self.parse(text)
    text
      .split("\n\n")
      .then do |dots, folds|
        new(
          dots.split.map { |d| d.split(",").map(&:to_i) },
          folds.split("\n").map { |f| Fold.parse(f) }
        )
      end
  end

  class Fold
    attr_reader :direction, :axis
    def initialize(direction, axis)
      @direction = direction
      @axis = axis
    end

    def self.parse(line)
      direction, axis = line.split.last.split("=")
      new(direction == "x" ? :vertical : :horizontal, axis.to_i)
    end
  end
end
