$_debug = false

class SnailfishNumber
  attr_reader :tokens
  def initialize(tokens)
    @tokens = tokens
  end

  def +(other)
    SnailfishNumber.new(["[", *self.tokens, ",", *other.tokens, "]"]).reduce
  end

  def reduce
    it = self

    loop do
      if it.should_explode?
        it = it.explode
      elsif it.should_split?
        it = it.split
      else
        return it
      end
    end
  end

  def magnitude
    magnitude_list(eval(to_s))
  end

  def magnitude_list(list)
    return list.to_i unless list.is_a? Array

    3 * magnitude_list(list.first) + 2 * magnitude_list(list.second)
  end

  def explode
    depth = 0
    tokens.each_with_index do |token, index|
      depth += 1 if token == "["
      depth -= 1 if token == "]"
      next unless depth == 5

      return(
        SnailfishNumber.new(
          merge_rightmost(tokens[...index], tokens[index + 1]) + [0] +
            merge_leftmost(tokens[index + 5..], tokens[index + 3])
        )
      )
    end

    raise "Unreachable"
  end

  def merge_leftmost(list, value)
    list.each_with_index do |token, index|
      next if "[],".include?(token.to_s)
      return list[...index] + [token + value] + list[index + 1..]
    end
  end

  def merge_rightmost(list, value)
    merge_leftmost(list.reverse, value).reverse!
  end

  def split
    tokens.each_with_index do |token, index|
      next unless token.to_i >= 10
      return(
        SnailfishNumber.new(
          tokens[...index] +
            ["[", (token / 2.to_f).floor, ",", (token / 2.to_f).ceil, "]"] +
            tokens[(index + 1)..]
        )
      )
    end

    raise "Unreachable"
  end

  def should_explode?
    depth = 0
    tokens.each do |token|
      depth += 1 if token == "["
      depth -= 1 if token == "]"
      return true if depth == 5
    end
    false
  end

  def should_split?
    tokens.any? { |token| token.to_i >= 10 }
  end

  def to_s
    tokens.map(&:to_s).join
  end

  def ==(other)
    to_s == other.to_s
  end

  def self.final_sum(text)
    text.split.map { |line| parse(line) }.reduce(&:+).reduce
  end

  def self.largest_sum(text)
    i = 0
    text
      .split
      .map { |line| parse(line) }
      .permutation(2)
      .map do |pair|
        _debug("Working permutations...", i:) if (i += 1) % 100 == 0
        pair.reduce(&:+).magnitude
      end
      .max
  end

  def self.parse(string)
    new(string.chars.map { |ch| "[],".include?(ch) ? ch : ch.to_i })
  end
end

def sn(x) = SnailfishNumber.parse(x)
def sum(x) = SnailfishNumber.final_sum(x)
def mag(x) = SnailfishNumber.final_sum(x).magnitude

$hw = <<~list
  [[[0,[5,8]],[[1,7],[9,6]]],[[4,[1,2]],[[1,4],2]]]
  [[[5,[2,8]],4],[5,[[9,9],0]]]
  [6,[[[6,2],[5,6]],[[7,6],[4,7]]]]
  [[[6,[0,7]],[0,9]],[4,[9,[9,0]]]]
  [[[7,[6,4]],[3,[1,3]]],[[[5,5],1],9]]
  [[6,[[7,3],[3,2]]],[[[3,8],[5,7]],4]]
  [[[[5,4],[7,7]],8],[[8,3],8]]
  [[9,3],[[9,9],[6,[4,9]]]]
  [[2,[[7,7],7]],[[5,8],[[9,3],[0,2]]]]
  [[[[5,2],5],[8,[3,7]]],[[5,[7,5]],[4,4]]]
list

def test
  assert_equals! sn("[1,2]") + sn("[[3,4],5]"), sn("[[1,2],[[3,4],5]]")

  assert_equals! sn("[[[[[9,8],1],2],3],4]").explode, sn("[[[[0,9],2],3],4]")
  assert_equals! sn("[7,[6,[5,[4,[3,2]]]]]").explode, sn("[7,[6,[5,[7,0]]]]")
  assert_equals! sn("[[6,[5,[4,[3,2]]]],1]").explode, sn("[[6,[5,[7,0]]],3]")
  assert_equals! sn("[[3,[2,[1,[7,3]]]],[6,[5,[4,[3,2]]]]]").explode,
                 sn("[[3,[2,[8,0]]],[9,[5,[4,[3,2]]]]]")
  assert_equals! sn("[[3,[2,[8,0]]],[9,[5,[4,[3,2]]]]]").explode,
                 sn("[[3,[2,[8,0]]],[9,[5,[7,0]]]]")

  assert_equals! sn("[[[[4,3],4],4],[7,[[8,4],9]]]") + sn("[1,1]"),
                 sn("[[[[0,7],4],[[7,8],[6,0]]],[8,1]]")

  assert_equals! sum(<<~list), sn("[[[[1,1],[2,2]],[3,3]],[4,4]]")
  [1,1]
  [2,2]
  [3,3]
  [4,4]
  list

  assert_equals! sum(<<~list), sn("[[[[3,0],[5,3]],[4,4]],[5,5]]")
  [1,1]
  [2,2]
  [3,3]
  [4,4]
  [5,5]
  list

  assert_equals! sum(<<~list), sn("[[[[5,0],[7,4]],[5,5]],[6,6]]")
  [1,1]
  [2,2]
  [3,3]
  [4,4]
  [5,5]
  [6,6]
  list

  assert_equals! sum(<<~list),
  [[[0,[4,5]],[0,0]],[[[4,5],[2,6]],[9,5]]]
  [7,[[[3,7],[4,3]],[[6,3],[8,8]]]]
  [[2,[[0,8],[3,4]]],[[[6,7],1],[7,[1,6]]]]
  [[[[2,4],7],[6,[0,5]]],[[[6,8],[2,8]],[[2,1],[4,5]]]]
  [7,[5,[[3,8],[1,4]]]]
  [[2,[2,2]],[8,[8,1]]]
  [2,9]
  [1,[[[9,3],9],[[9,0],[0,7]]]]
  [[[5,[7,4]],7],1]
  [[[[4,2],2],6],[8,7]]
  list
                 sn("[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]")

  assert_equals! mag("[[9,1],[1,9]]"), 129
  assert_equals! mag("[[1,2],[[3,4],5]]"), 143
  assert_equals! mag("[[[[0,7],4],[[7,8],[6,0]]],[8,1]]"), 1384
  assert_equals! mag("[[[[1,1],[2,2]],[3,3]],[4,4]]"), 445
  assert_equals! mag("[[[[3,0],[5,3]],[4,4]],[5,5]]"), 791
  assert_equals! mag("[[[[5,0],[7,4]],[5,5]],[6,6]]"), 1137
  assert_equals! mag("[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]"),
                 3488

  assert_equals! sum($hw),
                 sn(
                   "[[[[6,6],[7,6]],[[7,7],[7,0]]],[[[7,7],[7,7]],[[7,8],[9,9]]]]"
                 )
  assert_equals! mag($hw), 4140

  :success
end

def solve = [mag(read_input), SnailfishNumber.largest_sum(read_input)]
