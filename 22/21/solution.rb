$_debug = false

def solve(input = read_input) =
  Monkeys.parse(input).then { |m| [m.root, m.root_solver] }

class Monkeys
  shape :instructions

  class << self
    def parse(example)
      new(instructions: example.lines.map { |l| l.chomp.split(": ") }.to_h)
    end
  end

  def root
    @variables = true
    parse_root.evaluate
  end

  def root_solver
    @variables = false
    parse_root.solve
  end

  def parse_root
    parse("root")
  end

  def parse(node)
    return human(node) if node == "humn" && !@variables
    return equal(node) if node == "root" && !@variables

    case inst(node)
    when /\d+/
      number(node)
    when /\w+ \* \w+/
      multiply(node)
    when /\w+ \+ \w+/
      add(node)
    when %r{\w+ / \w+}
      divide(node)
    when /\w+ - \w+/
      subtract(node)
    else
      raise "Unknown instruction: #{inst(node)}"
    end
  end

  def human(node)
    Variable["humn"]
  end

  def equal(node)
    left, right = inst(node).split(/ . /)
    Equal[parse(left), parse(right)]
  end

  def number(node)
    Number[inst(node).to_i]
  end

  def multiply(node)
    left, right = inst(node).split(" * ")
    Multiply[parse(left), parse(right)]
  end

  def add(node)
    left, right = inst(node).split(" + ")
    Add[parse(left), parse(right)]
  end

  def divide(node)
    left, right = inst(node).split(" / ")
    Divide[parse(left), parse(right)]
  end

  def subtract(node)
    left, right = inst(node).split(" - ")
    Subtract[parse(left), parse(right)]
  end

  def inst(monkey)
    instructions[monkey]
  end

  class Number < Struct.new(:value)
    def value? = true
    def variable? = false
    def evaluate
      value
    end

    def solve
      value
    end

    def reduce
      self
    end

    def to_s = value.to_s
  end

  class Equal < Struct.new(:left, :right)
    def value? = false
    def variable? = false
    def evaluate
      raise "Cannot evaluate equals"
    end

    def solve
      _debug("reducing", eq: to_s)
      self.left = left.reduce
      self.right = right.reduce
      _debug("solving", eq: to_s)

      return right.evaluate if left.variable?
      return left.evaluate if right.variable?

      return right.equate(left.evaluate).solve if left.value?
      return left.equate(right.evaluate).solve if right.value?

      raise "Cannot solve #{self}"
    end

    def to_s = "(#{left}) = (#{right})"
  end

  class Add < Struct.new(:left, :right)
    def value? = false
    def variable? = false
    def evaluate
      left.evaluate + right.evaluate
    end

    def reduce
      l = left.reduce
      r = right.reduce

      return Number[l.evaluate + r.evaluate] if l.value? && r.value?

      Add[l, r]
    end

    def equate(value)
      return Equal[left, Number[value - right.evaluate]] if right.value?
      return Equal[right, Number[value - left.evaluate]] if left.value?

      raise "Cannot equate non-values"
    end

    def to_s = "(#{left}) + (#{right})"
  end

  class Subtract < Struct.new(:left, :right)
    def value? = false
    def variable? = false
    def evaluate
      left.evaluate - right.evaluate
    end

    def reduce
      l = left.reduce
      r = right.reduce

      return Number[l.evaluate - r.evaluate] if l.value? && r.value?

      Subtract[l, r]
    end

    def equate(value)
      return Equal[left, Number[value + right.evaluate]] if right.value?
      return Equal[right, Number[left.evaluate - value]] if left.value?

      raise "Cannot equate non-values"
    end

    def to_s = "(#{left}) - (#{right})"
  end

  class Multiply < Struct.new(:left, :right)
    def value? = false
    def variable? = false
    def evaluate
      left.evaluate * right.evaluate
    end

    def reduce
      l = left.reduce
      r = right.reduce

      return Number[l.evaluate * r.evaluate] if l.value? && r.value?

      Multiply[l, r]
    end

    def equate(value)
      return Equal[left, Number[value / right.evaluate]] if right.value?
      return Equal[right, Number[value / left.evaluate]] if left.value?

      raise "Cannot equate non-values"
    end

    def to_s = "(#{left}) * (#{right})"
  end

  class Divide < Struct.new(:left, :right)
    def value? = false
    def variable? = false
    def evaluate
      left.evaluate / right.evaluate
    end

    def reduce
      l = left.reduce
      r = right.reduce

      return Number[l.evaluate / r.evaluate] if l.value? && r.value?

      Divide[l, r]
    end

    def equate(value)
      return Equal[left, Number[value * right.evaluate]] if right.value?
      return Equal[right, Number[left.evaluate / value]] if left.value?

      raise "Cannot equate non-values"
    end

    def to_s = "(#{left}) * (#{right})"
  end

  class Variable < Struct.new(:name)
    def value? = false
    def variable? = true
    def evaluate
      raise "Cannot evaluate variables"
    end

    def reduce
      self
    end

    def to_s = name
  end
end
