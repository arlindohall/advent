$_debug = true

def solve
  [Homework.new(read_input).sum, Homework.new(read_input).precedence_sum]
end

class Homework < Struct.new(:text)
  def sum
    expressions.map(&:evaluate).sum
  end

  def lines
    @lines ||= text.split("\n")
  end

  def expressions
    lines.map { |line| Expression.new(line) }
  end

  def precedence_sum
    precedence_expressions.map(&:evaluate).sum
  end

  def precedence_expressions
    lines.map { |line| PrecedenceExpression.new(line) }
  end
end

<<doc
expression := group operation*
operation := op group
group := number | "(" expression ")"
op := "+" | "*"
number := [0-9]+
doc
class Expression < Struct.new(:source)
  def evaluate
    parse.evaluate
  end

  def parse
    @index = 0
    expr = parse_expr
    assert_done!

    expr
  end

  def parse_expr
    _debug("parsing expression")

    group = parse_group
    operations = []
    operations << parse_operation while op_next?

    Expr.new(group, operations)
  end

  def parse_group
    _debug("parsign group")
    return parse_number if number_next?

    consume(:left_paren)
    expr = parse_expr
    consume(:right_paren)

    Group.new(expr)
  end

  def parse_operation
    _debug("parsing operation")
    op = parse_op
    group = parse_group

    Operation.new(op, group)
  end

  def parse_op
    _debug("parsing op")
    raise "Unexpected type #{type}" unless op_next?
    advance.type
  end

  def parse_number
    _debug("parsing number")
    Number.new(advance.source)
  end

  def number_next?
    current&.type == :number
  end

  def op_next?
    %i[plus times].include?(current&.type)
  end

  def current
    tokens[index]
  end

  def advance
    @index += 1
    tokens[index - 1]
  end

  def consume(type)
    unless current&.type == type
      raise "Unexpected token #{index}/#{current}, wanted #{type}"
    end
    advance
  end

  def assert_done!
    unless index == tokens.length
      raise "Expected end of input, got #{index}=#{current} in #{tokens.map(&:type)}"
    end
  end

  def _debug(*args)
    return unless $_debug
    [*args, current&.source].plopp
  end

  module DebuggableExpression
    def _debug(*args)
      return unless $_debug
      args.plopp
    end
  end

  class Expr < Struct.new(:group, :operations)
    include DebuggableExpression

    def evaluate
      acc = group.evaluate

      _debug("evaluating expression", acc)
      while op = operations.shift
        acc = apply(acc, op)
        _debug("updated accumulator", acc)
      end

      acc
    end

    def apply(accumulator, operation)
      case operation.type
      when :plus
        accumulator + operation.evaluate
      when :times
        accumulator * operation.evaluate
      end
    end
  end

  class Operation < Struct.new(:type, :group)
    include DebuggableExpression

    def evaluate
      _debug("evaluating operation", type)
      group.evaluate
    end
  end

  class Group < Struct.new(:expression)
    include DebuggableExpression

    def evaluate
      _debug("evaluating group")
      expression.evaluate
    end
  end

  class Number < Struct.new(:value)
    include DebuggableExpression

    def evaluate
      _debug("evaluating number", value)
      value.to_i
    end
  end

  def tokens
    @tokens ||= tokenize
  end

  def tokenize
    tokens = []
    @token_index = 0
    until done_tokenizing?
      skip_whitespace
      tokens << read_token
    end
    tokens
  end

  def read_token
    case current_token
    when "(", ")", "+", "*"
      read_symbol
    when /[0-9]/
      read_number
    else
      raise "Unknown value"
    end
  end

  def read_symbol
    symbol = current_token
    advance_token

    case symbol
    when "("
      Token.new(:left_paren, symbol)
    when ")"
      Token.new(:right_paren, symbol)
    when "*"
      Token.new(:times, symbol)
    when "+"
      Token.new(:plus, symbol)
    else
      raise "Unknown symbol #{symbol}"
    end
  end

  def read_number
    number = []
    number << advance_token while current_token&.match(/[0-9]/)
    Token.new(:number, number.join)
  end

  def done_tokenizing?
    token_index >= source.length
  end

  def skip_whitespace
    advance_token while current_token.match(/\s/)
  end

  def advance_token
    @token_index += 1
    source[token_index - 1]
  end

  def current_token
    source[token_index]
  end

  class Token < Struct.new(:type, :source)
  end

  attr_reader :token_index, :index
end

<<doc
expression := factor ("*" factor)*
factor := addend ("+" addend)*
addend := number | group
group := "(" expression ")"
number := [0-9]+
doc
class PrecedenceExpression < Expression
  def parse_expr
    _debug("parsing expression")

    factors = [parse_factor]
    while times_next?
      consume(:times)
      factors << parse_factor
    end

    Product.new(factors)
  end

  def parse_factor
    _debug("parsing factor")

    addends = [parse_addend]
    while plus_next?
      consume(:plus)
      addends << parse_addend
    end

    Sum.new(addends)
  end

  def parse_addend
    return parse_number if number_next?
    return parse_group if group_next?

    raise "Unknown addend type #{current.source}"
  end

  def group_next?
    current&.type == :left_paren
  end

  def times_next?
    current&.type == :times
  end

  def plus_next?
    current&.type == :plus
  end

  class Sum < Struct.new(:addends)
    include Expression::DebuggableExpression

    def evaluate
      _debug("evaluating sum", addends.map(&:evaluate).sum)
      addends.map(&:evaluate).sum
    end
  end

  class Product < Struct.new(:factors)
    include Expression::DebuggableExpression

    def evaluate
      _debug("evaluating product", factors.map(&:evaluate).product)
      factors.map(&:evaluate).product
    end
  end
end
