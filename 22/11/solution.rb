def solve =
  read_input.then do |it|
    [
      KeepAway.parse(it).monkey_business,
      KeepAway.parse(it).maximum_monkey_business
    ]
  end

class KeepAway
  shape :monkeys, :monkey_counts

  def monkey_business(n = 20)
    n.times { round }
    monkey_counts.sort.last(2).product
  end

  def maximum_monkey_business(n = 10_000)
    n.times { round(with_modulus: true) }
    monkey_counts.sort.last(2).product
  end

  def monkey_modulus
    @mod ||= monkeys.values.map(&:test).uniq.reduce(:lcm)
  end

  def round(with_modulus: false)
    @monkey_counts ||= []

    monkeys.each do |id, monkey|
      passes = monkey.round(no_div: with_modulus)

      monkey_counts[id] ||= 0
      passes.each do |new_value, dest_monkey|
        monkey_counts[id] += 1
        new_value = new_value % monkey_modulus if with_modulus
        monkeys[dest_monkey].items << new_value
      end

      monkey.clear_items!
    end

    monkey_counts
  end

  def self.parse(text)
    new(
      monkeys:
        text
          .scan(
            /
            Monkey[ ](\d+):\s+                    # id
              Starting[ ]items: ([\d,\s]+)\s+     # items
              Operation:[ ].*old[ ]([^\n]+)\s+    # operation
              Test:[ ].*by[ ](\d+)\s+             # test
                If[ ]true:[ ].*monkey[ ](\d+)\s+  # true
                If[ ]false:[ ].*monkey[ ](\d+)    # false
            /x
          )
          .map do |id, items, operation, test, if_true, if_false|
            Monkey.new(
              id: id.to_i,
              items: items.split.map(&:to_i),
              operation: operation.split,
              test: test.to_i,
              if_true: if_true.to_i,
              if_false: if_false.to_i
            )
          end
          .hash_by(&:id)
    )
  end

  class Monkey
    shape :id, :items, :operation, :test, :if_true, :if_false

    def round(no_div: false)
      # puts "Monkey #{id}:"
      items.map do |item|
        # debug(item)
        worry = new_worry(item, no_div)
        [worry, next_monkey(worry)]
      end
    end

    def clear_items!
      @items = []
    end

    def new_worry(item, no_div)
      no_div ? apply_operation(item) : apply_operation(item) / 3
    end

    def apply_operation(item)
      case operation.first
      when "*"
        item * number(operation.last, item)
      when "+"
        item + number(operation.last, item)
      else
        raise "Unknown operation #{operation.first}"
      end
    end

    def number(operand, value)
      case operand
      when /\d+/
        operand.to_i
      when "old"
        value
      else
        raise "Unknown operand #{operand}"
      end
    end

    def next_monkey(worry)
      if worry % test == 0
        if_true
      else
        if_false
      end
    end

    def debug(item)
      print "  "
      puts <<~str
        Monkey inspects an item with worry level #{item}
            Worry level #{op_string} by #{number(operation.last, item)} to #{apply_operation(item)}
            Monkey gets bored with item. Worry level is divided by 3 to #{apply_operation(item) / 3}.
            Current worry level is #{(apply_operation(item) / 3) % test == 0 ? "" : "not "}divisible by #{test}.
            Item with worry #{apply_operation(item) / 3} is passed to monkey #{next_monkey(apply_operation(item) / 3)}.
      str
    end

    def op_string
      case operation.first
      when "*"
        "is multiplied"
      when "+"
        "increases"
      else
        raise "Unknown operation #{operation.first}"
      end
    end
  end
end
