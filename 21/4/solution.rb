def solve =
  [
    BingoPlayer.new(read_input).final_score,
    BingoPlayer.new(read_input).losing_score
  ]

class BingoPlayer
  attr_reader :text
  def initialize(text)
    @text = text
  end

  def final_score
    unmarked * last_called.to_i
  end

  def losing_score
    loser_unmarked * last_called.to_i
  end

  private

  def unmarked
    winning_board.unmarked(called).map(&:to_i).sum
  end

  def loser_unmarked
    losing_board.unmarked(called).map(&:to_i).sum
  end

  def last_called
    called.last
  end

  def round
    @index ||= 0

    raise "All numbers called" if @index >= numbers.size

    called << numbers[@index]

    @index += 1
  end

  def winning_board
    return @winning_board if @winning_board

    round until boards.any? { |board| board.wins?(called) }

    @winning_board = boards.only! { |board| board.wins?(called) }
  end

  def losing_board
    return @losing_board if @losing_board

    round until boards.count { |board| !board.wins?(called) } == 1

    @losing_board = boards.only! { |board| !board.wins?(called) }

    round until boards.all? { |board| board.wins?(called) }

    @losing_board
  end

  def called
    @called ||= []
  end

  def boards
    @boards ||= text.split("\n\n").drop(1).map { |board| BingoBoard.new(board) }
  end

  def numbers
    @numbers ||= text.split("\n").first.split(",")
  end

  class BingoBoard
    attr_reader :text
    def initialize(text)
      @text = text
    end

    def rows
      @rows ||= text.split("\n").map(&:split)
    end

    def columns
      @columns ||= rows.transpose
    end

    # def diagonals
    #   @diagonals ||=
    #     rows
    #       .each_with_index
    #       .map { |row, idx| [row[idx], row[row.size - 1 - idx]] }
    #       .transpose
    # end

    def matches
      @matches || rows + columns
    end

    def unmarked(called)
      rows.flatten - called
    end

    def wins?(called)
      matches.any? { |match| match.all? { |square| called.include?(square) } }
    end
  end
end
