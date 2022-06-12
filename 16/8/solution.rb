
class Display
  def initialize(rows = 6, cols = 50)
    reset(rows, cols)
  end

  def reset(rows = 3, cols = 7)
    @rows = rows.times.map do |row|
      cols.times.map do |col|
        '.'
      end.to_a
    end.to_a
  end

  def run_instructions(lines)
    lines.each do |line|
      parse(line).call
      show
    end

    @rows.flatten.count('#')
  end

  def show
    puts @rows.map(&:join).join("\n"), ''
  end

  def rows
    @rows
  end

  private

    def translate
      @rows = @rows.transpose
    end

    def rect(y, x)
      0.upto(x-1) do |i|
        0.upto(y-1) do |j|
          @rows[i][j] = '#'
        end
      end
    end

    def rotate_row(row, number)
      @rows[row].rotate!(-number)
    end

    def rotate_col(col, number)
      translate
      rotate_row(col, number)
      translate
    end

    def parse(line)
      if line.split.first == "rect"
        y,x = line.split.last.split('x').map(&:to_i)
        ->{ rect(y, x) }
      elsif line.split[1] == "column"
        col, number = line.split('=').last.split(' by ').map(&:to_i)
        ->{ rotate_col(col, number) }
      elsif line.split[1] == "row"
        row, number = line.split('=').last.split(' by ').map(&:to_i)
        ->{ rotate_row(row, number) }
      else
        raise "Unknown instruction: #{line}"
      end
    end
end

@example = %Q(
  rect 3x2
  rotate column x=1 by 1
  rotate row y=0 by 4
  rotate column x=1 by 1
).strip.lines.map(&:strip)

@input = %Q(
  rect 1x1
  rotate row y=0 by 5
  rect 1x1
  rotate row y=0 by 5
  rect 1x1
  rotate row y=0 by 3
  rect 1x1
  rotate row y=0 by 2
  rect 1x1
  rotate row y=0 by 3
  rect 1x1
  rotate row y=0 by 2
  rect 1x1
  rotate row y=0 by 5
  rect 1x1
  rotate row y=0 by 5
  rect 1x1
  rotate row y=0 by 3
  rect 1x1
  rotate row y=0 by 2
  rect 1x1
  rotate row y=0 by 3
  rect 2x1
  rotate row y=0 by 2
  rect 1x2
  rotate row y=1 by 5
  rotate row y=0 by 3
  rect 1x2
  rotate column x=30 by 1
  rotate column x=25 by 1
  rotate column x=10 by 1
  rotate row y=1 by 5
  rotate row y=0 by 2
  rect 1x2
  rotate row y=0 by 5
  rotate column x=0 by 1
  rect 4x1
  rotate row y=2 by 18
  rotate row y=0 by 5
  rotate column x=0 by 1
  rect 3x1
  rotate row y=2 by 12
  rotate row y=0 by 5
  rotate column x=0 by 1
  rect 4x1
  rotate column x=20 by 1
  rotate row y=2 by 5
  rotate row y=0 by 5
  rotate column x=0 by 1
  rect 4x1
  rotate row y=2 by 15
  rotate row y=0 by 15
  rotate column x=10 by 1
  rotate column x=5 by 1
  rotate column x=0 by 1
  rect 14x1
  rotate column x=37 by 1
  rotate column x=23 by 1
  rotate column x=7 by 2
  rotate row y=3 by 20
  rotate row y=0 by 5
  rotate column x=0 by 1
  rect 4x1
  rotate row y=3 by 5
  rotate row y=2 by 2
  rotate row y=1 by 4
  rotate row y=0 by 4
  rect 1x4
  rotate column x=35 by 3
  rotate column x=18 by 3
  rotate column x=13 by 3
  rotate row y=3 by 5
  rotate row y=2 by 3
  rotate row y=1 by 1
  rotate row y=0 by 1
  rect 1x5
  rotate row y=4 by 20
  rotate row y=3 by 10
  rotate row y=2 by 13
  rotate row y=0 by 10
  rotate column x=5 by 1
  rotate column x=3 by 3
  rotate column x=2 by 1
  rotate column x=1 by 1
  rotate column x=0 by 1
  rect 9x1
  rotate row y=4 by 10
  rotate row y=3 by 10
  rotate row y=1 by 10
  rotate row y=0 by 10
  rotate column x=7 by 2
  rotate column x=5 by 1
  rotate column x=2 by 1
  rotate column x=1 by 1
  rotate column x=0 by 1
  rect 9x1
  rotate row y=4 by 20
  rotate row y=3 by 12
  rotate row y=1 by 15
  rotate row y=0 by 10
  rotate column x=8 by 2
  rotate column x=7 by 1
  rotate column x=6 by 2
  rotate column x=5 by 1
  rotate column x=3 by 1
  rotate column x=2 by 1
  rotate column x=1 by 1
  rotate column x=0 by 1
  rect 9x1
  rotate column x=46 by 2
  rotate column x=43 by 2
  rotate column x=24 by 2
  rotate column x=14 by 3
  rotate row y=5 by 15
  rotate row y=4 by 10
  rotate row y=3 by 3
  rotate row y=2 by 37
  rotate row y=1 by 10
  rotate row y=0 by 5
  rotate column x=0 by 3
  rect 3x3
  rotate row y=5 by 15
  rotate row y=3 by 10
  rotate row y=2 by 10
  rotate row y=0 by 10
  rotate column x=7 by 3
  rotate column x=6 by 3
  rotate column x=5 by 1
  rotate column x=3 by 1
  rotate column x=2 by 1
  rotate column x=1 by 1
  rotate column x=0 by 1
  rect 9x1
  rotate column x=19 by 1
  rotate column x=10 by 3
  rotate column x=5 by 4
  rotate row y=5 by 5
  rotate row y=4 by 5
  rotate row y=3 by 40
  rotate row y=2 by 35
  rotate row y=1 by 15
  rotate row y=0 by 30
  rotate column x=48 by 4
  rotate column x=47 by 3
  rotate column x=46 by 3
  rotate column x=45 by 1
  rotate column x=43 by 1
  rotate column x=42 by 5
  rotate column x=41 by 5
  rotate column x=40 by 1
  rotate column x=33 by 2
  rotate column x=32 by 3
  rotate column x=31 by 2
  rotate column x=28 by 1
  rotate column x=27 by 5
  rotate column x=26 by 5
  rotate column x=25 by 1
  rotate column x=23 by 5
  rotate column x=22 by 5
  rotate column x=21 by 5
  rotate column x=18 by 5
  rotate column x=17 by 5
  rotate column x=16 by 5
  rotate column x=13 by 5
  rotate column x=12 by 5
  rotate column x=11 by 5
  rotate column x=3 by 1
  rotate column x=2 by 5
  rotate column x=1 by 5
  rotate column x=0 by 1
).strip.lines.map(&:strip)