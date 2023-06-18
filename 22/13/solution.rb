$_debug = false

def solve = PacketPairs.parse(read_input).then { |it| [it.part1, it.part2] }

class PacketPairs
  shape :pairs

  def part1 = ordered.sum
  def part2 =
    sorted
      .map(&:original)
      .then { |sorted| [sorted.index("[[2]]"), sorted.index("[[6]]")] }
      .map { |it| it + 1 }
      .product

  def ordered
    pairs
      .each_with_index
      .filter do |pair, _idx|
        pair.first.comes_before?(pair.second).tap { |it| puts it if $_debug } ==
          :right_order
      end
      .map { |_pair, idx| idx + 1 }
  end

  def sorted
    pairs_with_dividers.sort
  end

  def pairs_with_dividers
    pairs.flatten(1) +
      ["[[2]]", "[[6]]"].map { |it| [self.class.tokenize(it), it] }
        .map { |it, orig| self.class.list(it, orig) }
  end

  class << self
    def parse(text)
      new(
        pairs:
          text
            .split("\n\n")
            .map(&:split)
            .sub_map { |line| [tokenize(line), line] }
            .sub_map { |line, orig| list(line, orig) }
      )
    end

    def tokenize(line, result = [])
      return result if line.empty?

      if %w([ ] ,).include?(line[0])
        tokenize(line[1..], result.push(line[0]))
      else
        next_token = line.match(/\d+/)
        tokenize(line[next_token.size..], result.push(next_token.to_s))
      end
    end

    def list(tokens, original = nil)
      consume!(tokens, "[")
      items = []
      items << item(tokens) until tokens.first == "]" || tokens.empty?
      consume!(tokens, "]")

      List.new(items:, original:)
    end

    def item(tokens)
      item =
        case tokens.first
        when "["
          list(tokens)
        when /\d+/
          Value.new(value: tokens.shift.to_i)
        else
          raise "Parse error"
        end

      tokens.shift if tokens.first == ","

      item
    end

    def consume!(tokens, expected)
      raise "Parse error" unless tokens.shift == expected
    end
  end

  class List
    shape :items, :original
    def list? = true

    def literal
      items.map(&:literal)
    end

    def <=>(other)
      case comes_before?(other)
      when :wrong_order
        1
      when :right_order
        -1
      when :undecided
        0
      end
    end

    def comes_before?(other, indent = 0)
      return comes_before?(List.new(items: [other]), indent) unless other.list?

      puts "#{" " * indent}- Compare #{literal} vs #{other.literal}" if $_debug
      _debug("comparing list", zipped: literal.zip(other.literal))
      items
        .zip(other.items)
        .each do |item, other_item|
          _debug("comparing items", left: item, right: other_item)
          return :wrong_order if other_item.nil?

          result = item.comes_before?(other_item, indent + 2)
          return result unless result == :undecided
        end

      items.size < other.items.size ? :right_order : :undecided
    end
  end

  class Value
    shape :value
    def list? = false

    def literal
      value
    end

    def <=>(other)
      case comes_before?(other)
      when :wrong_order
        1
      when :right_order
        -1
      when :undecided
        0
      end
    end

    def comes_before?(other, indent = 0)
      puts "#{" " * indent}- Compare #{literal} vs #{other.literal}" if $_debug
      if other.list?
        List.new(items: [self]).comes_before?(other, indent + 2)
      elsif other.value == value
        :undecided
      elsif other.value < value
        :wrong_order
      else
        :right_order
      end
    end
  end
end
